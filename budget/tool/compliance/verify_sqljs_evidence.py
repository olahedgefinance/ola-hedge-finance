NAMES = ("sql-wasm.js", "worker.sql-wasm.js", "sql-wasm.wasm")

def compare_artifacts(built, shipped):
    if any(n not in built or n not in shipped or not built[n] or not shipped[n] for n in NAMES):
        return {"classification": "Build cannot be reproduced", "transforms": {}}
    transforms = {}
    for name in NAMES:
        a, b = built[name], shipped[name]
        if a == b:
            transforms[name] = "identity"
        elif name.endswith(".js") and b"\r" not in a and a.replace(b"\n", b"\r\n") == b:
            transforms[name] = "LF-to-CRLF"
        else:
            transforms[name] = "mismatch"
    return {"classification": "Build succeeds but provenance mismatch remains" if "mismatch" in transforms.values() else "Exact reproducible match", "transforms": transforms}

SOURCE_COMMIT = "997d56fb954b63e76cf8d549c4660c972381768e"
CONDITIONS = [
 "Technical evidence only; not legal/release clearance or Phase 2A completion.",
 "Contribution licence/attribution scope, compiler runtime notices and final release source/notices delivery remain unverified.",
 "Do Not Ship remains. Native production verification remains incomplete."]

def require(ok, message):
    if not ok:
        raise ValueError("SQL.js evidence: " + message)

def validate_metadata(m):
    require(m.get("version")=="1.6.2" and m.get("sourceCommit")==SOURCE_COMMIT, "release/source differs")
    require(m.get("expectedEmscripten")=="2.0.29" and m.get("observedEmscripten")=="2.0.29", "compiler differs from release recipe")
    require(type(m.get("buildExit")) is int and m["buildExit"]==0, "build did not succeed")
    require(all(m.get(k) is False for k in ("legalClearance","releaseClearance","gapClosed","publishedCompilerProven")), "unsupported clearance or publisher-history claim")
    require(m.get("conditions")==CONDITIONS, "conditions missing or altered")

import argparse,base64,hashlib,io,json,re,tarfile,urllib.request,zipfile
from pathlib import Path
EVIDENCE="compliance/evidence/reconstruction-2026-10-09/sqljs-build-2026-10-13"

def digest(b):return hashlib.sha256(b).hexdigest()

def zip_members(data):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names=z.namelist()
        require(len(names)==len(set(names)), "duplicate ZIP member")
        require(all(not n.startswith('/') and not any(t in n for t in ('\\',':')) and '..' not in n.split('/') for n in names), "unsafe ZIP member")
        return {n:z.read(n) for n in names if not n.endswith('/')}

def verify(root, manifest=None, replay=False):
    root=Path(root)
    m=manifest if manifest is not None else json.loads((root/EVIDENCE/'manifest.json').read_text())
    validate_metadata(m)
    seen={}
    def read(row):
        path=row['path'];h=row['sha256']
        require(re.fullmatch(r'[a-f0-9]{64}',h) is not None and path==EVIDENCE+'/blobs/'+h, 'unsafe evidence path or digest')
        b=(root/path).read_bytes();require(digest(b)==h,'evidence hash mismatch')
        if replay and 'url' in row and row['url'] not in seen:
            url=row['url'];require(url.startswith('https://'),'non-HTTPS acquisition')
            got=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'OLA-SQLjs-evidence-replay'}),timeout=90).read()
            require(got==b,'remote evidence differs: '+url);seen[url]=h
        return b
    expected={'source.zip':'https://codeload.github.com/sql-js/sql.js/zip/'+SOURCE_COMMIT,
      'npm.tgz':'https://registry.npmjs.org/sql.js/-/sql.js-1.6.2.tgz',
      'npm.json':'https://registry.npmjs.org/sql.js/1.6.2',
      'tag.json':'https://api.github.com/repos/sql-js/sql.js/git/ref/tags/v1.6.2',
      'tag-object.json':'https://api.github.com/repos/sql-js/sql.js/git/tags/122e8fdeba995e105a77265c401f3e2013f8a425',
      'release.json':'https://api.github.com/repos/sql-js/sql.js/releases/tags/v1.6.2',
      'sqlite.zip':'https://www.sqlite.org/2021/sqlite-amalgamation-3360000.zip',
      'sqljs-wasm.zip':'https://github.com/sql-js/sql.js/releases/download/v1.6.2/sqljs-wasm.zip',
      'sqljs-worker-wasm.zip':'https://github.com/sql-js/sql.js/releases/download/v1.6.2/sqljs-worker-wasm.zip',
      'emsdk.zip':'https://codeload.github.com/emscripten-core/emsdk/zip/refs/tags/2.0.29',
      'emsdk-tag.json':'https://api.github.com/repos/emscripten-core/emsdk/git/ref/tags/2.0.29',
      'extension-commit.json':'https://api.github.com/repos/dinedal/go-sqlite3-extension-functions/commits/master'}
    inputs=m['inputs'];require(set(inputs)==set(expected)|{'extension-functions.c'},'input coverage differs')
    for name,url in expected.items():require(inputs[name]['url']==url,'source URL differs: '+name)
    # Verify all bytes before using metadata; mutable API snapshots are retained, not trusted as live immutable identities.
    data={k:read({x:y for x,y in v.items() if x!='url'} if k.endswith('.json') else v) for k,v in inputs.items() if k!='extension-functions.c'}
    ext_commit=json.loads(data['extension-commit.json'])['sha']
    require(re.fullmatch('[a-f0-9]{40}',ext_commit) is not None,'invalid contribution commit')
    require(inputs['extension-functions.c']['url']=='https://raw.githubusercontent.com/dinedal/go-sqlite3-extension-functions/'+ext_commit+'/extension-functions.c','contribution source differs')
    data['extension-functions.c']=read(inputs['extension-functions.c'])
    ref=json.loads(data['tag.json']);tag=json.loads(data['tag-object.json'])
    require(ref['ref']=='refs/tags/v1.6.2' and ref['object']['sha']==tag['sha']=='122e8fdeba995e105a77265c401f3e2013f8a425','tag reference mismatch')
    require(tag['tag']=='v1.6.2' and tag['object']=={'sha':SOURCE_COMMIT,'type':'commit','url':'https://api.github.com/repos/sql-js/sql.js/git/commits/'+SOURCE_COMMIT},'tag target mismatch')
    npm=json.loads(data['npm.json']);require(npm['name']=='sql.js' and npm['version']=='1.6.2' and npm['gitHead']==SOURCE_COMMIT,'npm source mismatch')
    require(npm['dist']['tarball']==expected['npm.tgz'] and npm['dist']['integrity']=='sha512-'+base64.b64encode(hashlib.sha512(data['npm.tgz']).digest()).decode(),'npm archive authentication failed')
    source=zip_members(data['source.zip']);prefix='sql.js-'+SOURCE_COMMIT+'/'
    require(all(n.startswith(prefix) for n in source),'source archive root mismatch');source={n[len(prefix):]:b for n,b in source.items()}
    require(m['buildInputHashes']=={n:digest(b) for n,b in source.items()},'build source differs or is incomplete')
    pkg=json.loads(source['package.json']);require(pkg['name']=='sql.js' and pkg['version']=='1.6.2' and pkg['license']=='MIT','upstream package differs')
    docker=source['.devcontainer/Dockerfile'].decode();make=source['Makefile'].decode()
    require(re.findall(r'^ENV EMSCRIPTEN_VERSION (\S+)',docker,re.M)==['2.0.29'],'active upstream compiler pin differs')
    require('uses: ./.github/actions/build-sqljs' in source['.github/workflows/release.yml'].decode() and "image: '../../../.devcontainer/Dockerfile'" in source['.github/actions/build-sqljs/action.yml'].decode() and 'npm run rebuild' in source['.github/actions/build-sqljs/entrypoint.sh'].decode(),'release-to-compiler chain differs')
    require('Last built with version 2.0.15' in make,'compiler-history context differs')
    sql_sha=re.search(r'^SQLITE_AMALGAMATION_ZIP_SHA3 = ([a-f0-9]+)',make,re.M).group(1)
    ext_sha=re.search(r'^EXTENSION_FUNCTIONS_SHA1 = ([a-f0-9]+)',make,re.M).group(1)
    require(hashlib.sha3_256(data['sqlite.zip']).hexdigest()==sql_sha and hashlib.sha1(data['extension-functions.c']).hexdigest()==ext_sha,'SQLite/contribution input mismatch')
    sqlite=zip_members(data['sqlite.zip']);require(b'#define SQLITE_VERSION        "3.36.0"' in sqlite['sqlite-amalgamation-3360000/sqlite3.c'],'SQLite version mismatch')
    sdk=json.loads(data['emsdk-tag.json']);require(sdk['object']['sha']=='f9dee6673eb0692d79c45040448dfaafeb8842fb','emsdk revision mismatch')
    # Source and runtime licence scopes remain separate from package metadata.
    with tarfile.open(fileobj=io.BytesIO(data['npm.tgz']),mode='r:gz') as archive:
        require(len(archive.getnames())==len(set(archive.getnames())),'duplicate npm member')
        published={n:archive.extractfile('package/dist/'+n).read() for n in NAMES}
        for n in ('LICENSE','AUTHORS'):
            require(archive.extractfile('package/'+n).read()==source[n],'npm/source licence or author mismatch')
    require(json.loads(data['release.json'])['tag_name']=='v1.6.2','GitHub release mismatch')
    release=zip_members(data['sqljs-wasm.zip']);worker=zip_members(data['sqljs-worker-wasm.zip'])
    require(release['sql-wasm.js']==published['sql-wasm.js'] and release['sql-wasm.wasm']==published['sql-wasm.wasm'] and worker['worker.sql-wasm.js']==published['worker.sql-wasm.js'] and worker['sql-wasm.wasm']==published['sql-wasm.wasm'],'npm/GitHub binaries differ')
    require(set(m['outputs'])==set(NAMES),'replay output coverage differs')
    built={n:read(m['outputs'][n]) for n in NAMES};shipped={n:(root/'budget/web'/n).read_bytes() for n in NAMES}
    require(len(m['records'])==3 and {r['path'] for r in m['records']}=={'budget/web/'+n for n in NAMES},'distributed artifact coverage differs')
    for r in m['records']:
        n=Path(r['path']).name;require(r['sha256']==digest(shipped[n]) and r['publishedSha256']==digest(published[n]),'shipped/published hash mismatch')
    require(compare_artifacts(published,shipped)['classification']=='Exact reproducible match','distributed files differ from published release')
    comparison=compare_artifacts(built,shipped);require(comparison==m['comparison'],'recorded replay comparison differs')
    require(set(m['repeatOutputs'])==set(NAMES) and m['repeatBuild']['exit']==0,'repeat output coverage or build failure')
    repeated={n:read(m['repeatOutputs'][n]) for n in NAMES}
    require(m['repeatBuild']['sameAsFirst'] is all(repeated[n]==built[n] for n in NAMES),'repeatability claim differs from bytes')
    archives=m['toolArchives']
    require(len(archives)==5 and len({r['filename'] for r in archives})==5,'missing/duplicate tool archive provenance')
    for row in archives:
        require(re.fullmatch('[a-f0-9]{64}',row['sha256']) is not None and type(row['bytes']) is int and row['bytes']>0,'invalid tool archive hash or size')
    installed=json.loads(read(m['sdkInstalledComparison']))
    expected_sdk={
      'node-v14.15.5-win-x64.zip':'deps/node-v14.15.5-win-x64.zip',
      'python-3.9.2-1-embed-amd64+pywin32.zip':'deps/python-3.9.2-1-embed-amd64+pywin32.zip',
      'portable_jre_8_update_152_64bit.zip':'deps/portable_jre_8_update_152_64bit.zip',
      'c2369dc425725fff86ba90a9007a4603ddf7941b-wasm-binaries.zip':'win/c2369dc425725fff86ba90a9007a4603ddf7941b/wasm-binaries.zip'}
    require(len(installed)==4 and {r['filename'] for r in installed}==set(expected_sdk),'SDK installed comparison coverage')
    for row in installed:
        require(row['url']=='https://storage.googleapis.com/webassembly/emscripten-releases-builds/'+expected_sdk[row['filename']],'wrong SDK archive URL')
        require(row['matchedFiles'] and not row['missing'],'SDK archive/installed tree discrepancy')
        if row['different']:
            change=row.get('documentedTransformation',{})
            require(row['filename'].endswith('-wasm-binaries.zip') and row['different']==['emscripten/emscripten-version.txt'],'unexplained installed difference')
            require(change.get('path')=='emscripten/emscripten-version.txt' and change.get('archiveText')=='"2.0.29"\n' and change.get('installedText')=='"2.0.29"\r\n','version transformation differs')
            require(digest(change['archiveText'].encode())==change['archiveSha256'] and digest(change['installedText'].encode())==change['installedSha256'],'version transformation hash differs')
        require({k:row[k] for k in ('filename','url','sha256','bytes')} in archives,'SDK archive record mismatch')
        require(all(re.fullmatch('[a-f0-9]{64}',f['sha256']) for f in row['matchedFiles']),'invalid installed file hash')
    read(m['buildLog'])
    for row in m['tools'].values():read(row)
    require('2.0.29 (28ca7fb7ce895b21013212e4644a5794a15a76f9)' in read(m['tools']['version-emcc.log']).decode(),'observed compiler log differs')
    return dict(version='1.6.2',sourceCommit=SOURCE_COMMIT,comparison=comparison,gapClosed=False,unresolvedLicenceReduction=0,replayedImmutableUrls=len(seen))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--replay',action='store_true');a=p.parse_args()
    print(json.dumps(verify(Path(__file__).resolve().parents[3],replay=a.replay),indent=2))
