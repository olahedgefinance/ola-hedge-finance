"""Verify retained four-fork delta evidence; never execute upstream source.
--source-root additionally replays source objects/archives and exact patches.
"""
from pathlib import Path
import argparse,hashlib,json,subprocess,tarfile,urllib.parse,os
REL=Path('compliance/evidence/reconstruction-2026-10-09/forks')
NAMES={'file_picker','reorderable_grid_view','sliding_sheet','implicitly_animated_reorderable_list'}
def require(condition,message):
    if not condition:raise ValueError(message)
def safe(path):
    require(isinstance(path,str) and path and not path.startswith('/') and ':' not in path and '\\' not in path and '..' not in path.split('/'),'unsafe path')
    return path
def sha(data):return hashlib.sha256(data).hexdigest()
def require_hash(data,expected):require(sha(data)==expected,'hash mismatch')
def canon(data):return (json.dumps(data,sort_keys=True,separators=(',',':'),ensure_ascii=False)+'\n').encode()
def inventory(files,modes=None):
    return [{'path':safe(p),'mode':(modes or {}).get(p,'100644'),'sha256':sha(b),'lfSha256':sha(b.replace(b'\r\n',b'\n')),'size':len(b),'gitBlob':hashlib.sha1(f'blob {len(b)}\0'.encode()+b).hexdigest()} for p,b in sorted(files.items())]
def delta(a,b):
    aa={safe(x['path']):x for x in a};bb={safe(x['path']):x for x in b}
    require(len(aa)==len(a) and len(bb)==len(b),'duplicate source paths')
    result=[]
    for p in sorted(aa.keys()|bb.keys()):
        x,y=aa.get(p),bb.get(p)
        if x==y:continue
        kind='added' if x is None else 'deleted' if y is None else 'line-endings-only' if x['lfSha256']==y['lfSha256'] and x['mode']==y['mode'] else 'modified'
        result.append({'path':p,'kind':kind,'before':x,'after':y})
    return result
def validate_delta(a,b,rows):require(delta(a,b)==rows,'incomplete or fabricated delta')
def has_git_ancestry(row):return row.get('comparisonKind')=='git-ancestor' and bool(row.get('upstreamCommit'))
def validate_provenance(row,proof):
    if row['source']=='git':
        for a,b in [('name','name'),('upstreamRepository','repository'),('upstreamCommit','base'),('forkCommit','fork'),('verifiedUpstreamTip','verifiedUpstreamTip')]:require(row[a]==proof[b],'Git provenance mismatch')
        require(proof['baseAncestorOfUpstream'] is True and proof['baseAncestorOfFork'] is True,'unverified ancestry')
    else:
        for key,other in [('archiveUrl','archive_url'),('archiveSha256','archive_sha256')]:require(row[key]==proof[other],'archive provenance mismatch')
        require(row['version']==proof['pubspec']['version']==row['upstreamVersion'] and row['name']==proof['pubspec']['name'],'published package identity mismatch')
        require(row['upstreamRepository']==proof['pubspec']['homepage'].split('/tree/')[0],'published repository mismatch')
        require(row['upstreamCommit'] is None and row['historicalGitBase'].startswith('UNAVAILABLE'),'unproven path ancestry')
def git(repo,*args):
    return subprocess.check_output(['git','-c','safe.directory='+Path(repo).as_posix(),'-C',str(repo),*args],stderr=subprocess.PIPE)
def git_files(repo,revision):
    rows=[]
    for raw in git(repo,'ls-tree','-rz',revision).split(b'\0'):
        if not raw:continue
        meta,path=raw.split(b'\t',1);mode,kind,oid=meta.decode().split();require(kind=='blob','unsupported Git submodule in source');rows.append((path.decode(),mode,oid))
    data=git_batch(repo,[x[2] for x in rows]);return {p:data[oid] for p,mode,oid in rows},{p:mode for p,mode,oid in rows}
def git_batch(repo,oids):
    raw=subprocess.check_output(['git','-c','safe.directory='+Path(repo).as_posix(),'-C',str(repo),'cat-file','--batch'],input=('\n'.join(oids)+'\n').encode());pos=0;result={}
    for oid in oids:
        end=raw.index(b'\n',pos);header=raw[pos:end].decode().split();require(header[0]==oid and header[1]=='blob','missing Git blob');size=int(header[2]);pos=end+1;result[oid]=raw[pos:pos+size];pos+=size+1
    return result
def archive_files(path):
    files={};modes={}
    with tarfile.open(path) as tar:
        for m in tar.getmembers():
            if m.isdir():continue
            require(m.isfile(),'unsupported archive entry');p=safe(m.name.removeprefix('./'));require(p not in files,'duplicate archive entry')
            files[p]=tar.extractfile(m).read();modes[p]='100755' if m.mode&0o111 else '100644'
    return files,modes
def git_patch(repo,base,head):return git(repo,'diff','--no-ext-diff','--no-textconv','--binary','--full-index','--no-renames',base,head)
def tree_patch(source_root,name,a,b):
    pair=source_root/(name+'-comparison')
    for label,files in [('upstream',a),('fork',b)]:
        dest=pair/label
        for p,data in files.items():
            f=dest/safe(p);f.parent.mkdir(parents=True,exist_ok=True)
            if f.exists():require(f.read_bytes()==data,'existing comparison bytes differ')
            else:f.write_bytes(data)
        require({p.relative_to(dest).as_posix() for p in dest.rglob('*') if p.is_file()}==set(files),'comparison tree extra files')
    proc=subprocess.run(['git','-c','core.autocrlf=false','-c','core.filemode=false','diff','--no-index','--no-ext-diff','--no-textconv','--binary','--full-index','--no-renames','--','upstream','fork'],cwd=pair,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    require(proc.returncode in (0,1),'tree diff failed')
    return normalise_patch(proc.stdout)
def normalise_patch(raw):
    lines=[]
    for line in raw.splitlines(keepends=True):
        if line.startswith((b'diff --git ',b'--- ',b'+++ ')):
            for prefix in [b'a/upstream/',b'a/fork/',b'b/upstream/',b'b/fork/']:
                line=line.replace(prefix,prefix[:2])
        lines.append(line)
    return b''.join(lines)
def load(folder,path):return json.loads((folder/safe(path)).read_text(encoding='utf-8'))
def verify(root,source_root=None):
    folder=root/REL;manifest=load(folder,'manifest.json');require(manifest['schemaVersion']==1,'schema')
    require_hash((root/'budget/pubspec.lock').read_bytes(),manifest['pubLockSha256'])
    rows=manifest['records'];require({r['name'] for r in rows}==NAMES and len(rows)==4,'coverage')
    config=json.loads((root/'budget/.dart_tool/package_config.json').read_text())
    for row in rows:
        for path,digest in row['evidenceHashes'].items():require_hash((folder/safe(path)).read_bytes(),digest)
        proofpath=row['name']+('/ancestry.json' if row['source']=='git' else '/pub-version.json')
        require(proofpath in row['evidenceHashes'],'missing provenance proof')
        validate_provenance(row,load(folder,proofpath))
        receiptpath=row['name']+'/patch-replay.json';headerpath=row['name']+'/header-review.json'
        require(receiptpath in row['evidenceHashes'] and headerpath in row['evidenceHashes'],'missing replay/header proof')
        receipt=load(folder,receiptpath);require(receipt['exactTargetTreeMatched'] is True and receipt['patchSha256']==sha((folder/row['patch']).read_bytes()) and receipt['replayedGitTree']==row.get('forkGitTree',row.get('canonicalTree')),'invalid patch replay proof')
        require(all(h['preserved'] and all(x in h['forkStatements'] for x in h['upstreamStatements']) for h in load(folder,headerpath)),'header loss')
        if row['source']=='git':
            for label,key in [('upstream','upstreamCommit'),('fork','forkCommit')]:
                path=row['name']+'/'+label+'-commit.txt';require(path in row['evidenceHashes'],'missing commit proof');raw=(folder/path).read_bytes()
                require(hashlib.sha1(f'commit {len(raw)}\0'.encode()+raw).hexdigest()==row[key],'commit object mismatch')
        a=load(folder,row['upstreamInventory']);b=load(folder,row['forkInventory']);d=load(folder,row['delta'])
        require_hash(canon(a),row['upstreamTreeSha256']);require_hash(canon(b),row['forkTreeSha256']);validate_delta(a,b,d)
        require(row['licence']=='MIT' and row['releaseClearance'] is False,'unsupported clearance')
        require((folder/row['upstreamLicence']).read_bytes().replace(b'\r\n',b'\n')==(folder/row['forkLicence']).read_bytes().replace(b'\r\n',b'\n'),'licence drift')
        require_hash((folder/row['upstreamLicence']).read_bytes(),next(x['sha256'] for x in a if x['path']=='LICENSE'))
        require_hash((folder/row['forkLicence']).read_bytes(),next(x['sha256'] for x in b if x['path']=='LICENSE'))
        if row['source']=='path':
            local=row['localPath'];safe(local)
            require(not git(root,'status','--porcelain','--',local).strip(),'dirty vendored source')
            current,modes=git_files(root,'HEAD:'+local)
            require(not has_git_ancestry(row) and row['upstreamCommit'] is None,'invented path ancestry')
            if source_root:
                archive=source_root/row['archiveFile'];require_hash(archive.read_bytes(),row['archiveSha256']);up,um=archive_files(archive)
                require(inventory(up,um)==a,'archive source drift')
                require_hash(tree_patch(source_root,row['name'],up,current),row['evidenceHashes'][row['patch']])
        else:
            package=next(x for x in config['packages'] if x['name']==row['name'])
            uri=urllib.parse.urlparse(package['rootUri']);require(uri.scheme=='file','Git dependency cache URI')
            path=urllib.parse.unquote(uri.path);path=path[1:] if os.name=='nt' and re_drive(path) else path;repo=Path(path)
            require(git(repo,'rev-parse','HEAD').decode().strip()==row['forkCommit'],'cache revision')
            require(not git(repo,'status','--porcelain').strip(),'dirty Git dependency cache')
            current,modes=git_files(repo,row['forkCommit'])
            if source_root:
                src=source_root/(row['name']+'.git');up,um=git_files(src,row['upstreamCommit'])
                require(inventory(up,um)==a,'upstream Git tree drift')
                git(src,'merge-base','--is-ancestor',row['upstreamCommit'],row['forkCommit'])
                git(src,'merge-base','--is-ancestor',row['upstreamCommit'],row['verifiedUpstreamTip'])
                require_hash(git_patch(src,row['upstreamCommit'],row['forkCommit']),row['evidenceHashes'][row['patch']])
        require(inventory(current,modes)==b,'live source differs from fork snapshot')
    return {'packages':4,'deltaRecords':sum(len(load(folder,r['delta'])) for r in rows),'sourceReplay':source_root is not None,'releaseClearance':False}
def re_drive(p):return len(p)>3 and p[0]=='/' and p[2]==':'
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--source-root',type=Path);args=parser.parse_args()
    root=Path(__file__).resolve().parents[3];print(json.dumps(verify(root,args.source_root)))
