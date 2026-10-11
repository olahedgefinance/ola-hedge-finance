"""Archive-integrity replay only. Dart generator validation is mandatory for source-scope/licence decisions; no package code executes."""
from pathlib import Path, PurePosixPath
import argparse,hashlib,io,json,re,tarfile,urllib.request,urllib.parse

REL='compliance/evidence/reconstruction-2026-10-09/pub-composite-2026-10-11'
MARKER=r'copyright|licen[sc]e|derived from|adapted from|aFileChooser|platform_detect|juniversalchardet|UniversalDetector|uchardet'
def require(ok,message):
    if not ok:raise ValueError(message)
def digest(data):return hashlib.sha256(data).hexdigest()
def safe(path):
    p=PurePosixPath(path)
    require(bool(path) and not p.is_absolute() and '..' not in p.parts and '\\' not in path and ':' not in path,'unsafe archive/evidence path')
def inventory(files):
    return [{'path':p,'bytes':len(b),'sha256':digest(b)} for p,b in sorted(files.items())]
def archive_files(raw,expected_sha):
    require(digest(raw)==expected_sha,'archive digest mismatch')
    files={}
    with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as archive:
        for item in archive.getmembers():
            safe(item.name)
            if item.isdir():continue
            require(item.isfile(),'non-regular archive member')
            require(item.name not in files,'duplicate archive member')
            files[item.name]=archive.extractfile(item).read()
    return files
def source_markers(files):
    result=[]
    for path,data in sorted(files.items()):
        try:text=data.decode('utf-8')
        except UnicodeDecodeError:continue
        markers=[{'line':i,'text':line} for i,line in enumerate(text.splitlines(),1) if re.search(MARKER,line,re.I)]
        if markers:result.append({'path':path,'sha256':digest(data),'markers':markers})
    return result
def validate_identity(row,release):
    spec=release['pubspec']
    require(row['source']=='hosted' and spec['name']==row['name'] and spec['version']==row['version']==release['version'],'release identity mismatch')
    require(row['archiveSha256']==release['archive_sha256'] and row['archiveUrl']==release['archive_url'],'release archive mismatch')
    require(urllib.parse.unquote(row['archiveUrl'])==f'https://pub.dev/api/archives/{row["name"]}-{row["version"]}.tar.gz','unexpected archive origin')
    require(row['sourceRepository']==spec.get('repository',spec.get('homepage')) and row['gitCommit'] is None and row['gitTag'] is None,'unproven repository mapping')
    require(row['legalClearance'] is False and row['releaseClearance'] is False,'unsupported clearance')
def validate_declaration(row):
    if row['classification'] in ['Needs Verification','Counsel Review Required']:
        require(row['declaration']=='NOASSERTION' and row['operator']=='UNRESOLVED' and not row['terms'] and bool(row['unresolvedReasons']),'unresolved promotion')
    else:
        ids=[t['spdx'] for t in row['terms']]
        require(row['classification']=='Verified with conditions' and bool(ids) and len(set(ids))==len(ids),'invalid reviewed grants')
        require(row['operator']==('SINGLE' if len(ids)==1 else 'AND') and row['declaration']==' AND '.join(sorted(ids)),'AND/OR or aggregate mismatch')
def verify(root,archive_root=None,online=False):
    folder=root/REL
    def payload(path):safe(path);return (folder/path).read_bytes()
    def load(path):return json.loads(payload(path))
    manifest=load('manifest.json');require(manifest['schemaVersion']==1 and manifest['releaseClearance'] is False,'invalid manifest')
    retained_pub={r['id']:r for r in json.loads((root/'compliance/evidence/reconstruction-2026-10-09/pub/manifest.json').read_text())['records']}
    lock=(root/'budget/pubspec.lock').read_text()
    names=set();verified_files=0;retained_count=0;archive_count=0
    for row in manifest['records']:
        name=row['name'];require(name not in names,'duplicate package');names.add(name)
        release=load(row['releaseMetadataPath']);validate_identity(row,release);validate_declaration(row)
        original=retained_pub['pub:'+name]
        require(original['version']==row['version'] and original['archiveSha256']==row['archiveSha256'],'original exact release mismatch')
        block=re.search(r'^  '+re.escape(name)+r':\n(.*?)(?=^  [^ ]|\Z)',lock,re.M|re.S)
        require(block is not None and f'version: "{row["version"]}"' in block[1] and row['archiveSha256'] in block[1] and 'source: hosted' in block[1],'lock identity mismatch')
        inv=load(row['archiveInventoryPath']);inv_by={r['path']:r for r in inv}
        require(len(inv)==len(inv_by) and inv,'duplicate/empty inventory')
        for f in inv:safe(f['path'])
        retained={}
        for f in row['retainedFiles']:
            path=f['archivePath'];safe(path)
            require(path not in retained and f['path']==f'{name}/source/{path}','retained source substitution')
            data=payload(f['path']);require(digest(data)==f['sha256']==inv_by[path]['sha256'] and len(data)==inv_by[path]['bytes'],'retained hash mismatch')
            retained[path]=data;retained_count+=1
        for term in row['terms']:
            data=retained[term['licencePath']].splitlines(keepends=True)
            require(1<=term['startLine']<=term['endLine']<=len(data),'invalid grant range')
            require(digest(b''.join(data[term['startLine']-1:term['endLine']]))==term['textSha256'],'grant hash mismatch')
            require(term['scopeFiles'] and all(p in retained for p in term['scopeFiles']),'missing source witness')
        for f in original['files']+[original['pubspec']]:
            path=Path(f['path']).name
            require(retained[path]==(root/f['path']).read_bytes(),'original retained notice drift')
        raw=None
        if archive_root is not None:raw=(archive_root/name/'archive.tar.gz').read_bytes()
        if online:
            with urllib.request.urlopen(f'https://pub.dev/api/packages/{name}/versions/{row["version"]}',timeout=60) as response:fresh=json.load(response)
            validate_identity(row,fresh)
            with urllib.request.urlopen(row['archiveUrl'],timeout=60) as response:downloaded=response.read()
            if raw is not None:require(raw==downloaded,'download/archive mismatch')
            raw=downloaded
        if raw is not None:
            files=archive_files(raw,row['archiveSha256'])
            require(inventory(files)==inv,'complete archive tree mismatch')
            require(all(files[p]==b for p,b in retained.items()),'retained bytes absent from archive')
            require(source_markers(files)==load(row['sourceMarkersPath']),'source marker drift')
            verified_files+=len(files);archive_count+=1
    return {'packages':len(names),'archivesReplayed':archive_count,'archiveFilesReplayed':verified_files,'retainedPayloads':retained_count,'releaseClearance':False,'declarationValidation':'NOT PERFORMED - run the Dart generator'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive-root',type=Path)
    parser.add_argument('--online',action='store_true')
    args=parser.parse_args()
    print(json.dumps(verify(Path(__file__).resolve().parents[3],args.archive_root,args.online)))
