"""Replay CocoaPods evidence without executing podspec Ruby or native builds.

Default: offline lock, spec SHA-1, payload SHA-256, source revision receipts,
and wrapper bindings. --online additionally rereads public specs/licences,
source refs and HTTP archives; it never writes the checkout. Optional archive
directories rehash separately preserved archive binaries.
"""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,urllib.request,tarfile,base64,zipfile,io

def digest(data,algorithm='sha256'):
    return hashlib.new(algorithm,data).hexdigest()

def replay(folder, archive_root=None, wrapper_archives=None, online=False):
    root=next(p for p in folder.parents if (p/'budget/ios/Podfile.lock').exists())
    manifest=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
    lock=(root/'budget/ios/Podfile.lock').read_bytes()
    assert digest(lock)==manifest['podLockSha256'], 'lock drift'
    checks={m.group(1).strip('"'):m.group(2) for m in re.finditer(r'^  (.+): ([0-9a-f]{40})$',lock.decode().replace('\r\n','\n'),re.M)}
    def payload(path):
        assert not Path(path).is_absolute() and ':' not in path and '\\' not in path and '..' not in path.split('/')
        return (folder/path).read_bytes()
    def download(url):
        assert url.startswith('https://')
        with urllib.request.urlopen(url,timeout=90) as response: return response.read()
    locktext=lock.decode().replace('\r\n','\n')
    registry=set()
    section=False
    for line in locktext.splitlines():
        if line=='SPEC REPOS:': section=True;continue
        if line and not line.startswith(' '): section=False
        if section and line.startswith('    - '): registry.add(line[6:].strip('"'))
    names=[row['name'] for row in manifest['records']]
    assert len(names)==len(set(names)) and set(names)==registry, 'registry coverage differs from lock'
    graph={};current=None
    for line in locktext.split('DEPENDENCIES:')[0].splitlines()[1:]:
        if line.startswith('  - ') and not line.startswith('    '):
            heading=line[4:].removesuffix(':').strip('"')
            match=re.fullmatch(r'(.+?) \(([^)]+)\)',heading)
            assert match, 'unparsed pod heading'
            current=match.group(1).split('/')[0];graph.setdefault(current,set())
        elif line.startswith('    - ') and current:
            name=line[6:].split(' (')[0].strip('"').split('/')[0]
            if name!=current:graph[current].add(name)
    online_count=0
    for row in manifest['records']:
        specbytes=payload(row['specFile']);spec=json.loads(specbytes)
        assert digest(specbytes,'sha1')==row['lockedSpecChecksum']==checks[row['name']]
        assert digest(specbytes)==row['specSha256']
        assert spec['name']==row['name'] and spec['version']==row['version']
        assert spec['source']==row['source'] and spec['license']==row['licenceMetadata']
        if row.get('licenceFile'):
            assert digest(payload(row['licenceFile']))==row['licenceSha256']
        source=row['source']
        if 'git' in source:
            repo=source['git'].removesuffix('.git')
            assert row['sourceRepository']==source['git'] and row['downloadLocation']==repo+'/tree/'+row['resolvedCommit']
            assert re.fullmatch('[0-9a-f]{40}',row['resolvedCommit'])
            path=row['licencePath']
            assert path and not path.startswith('/') and ':' not in path and '\\' not in path and '..' not in path.split('/')
            if isinstance(spec['license'],dict) and 'file' in spec['license']:assert path==spec['license']['file']
            assert repo.startswith('https://github.com/')
            slug=repo.removeprefix('https://github.com/')
            def verify_api(raw):
                proof=json.loads(raw)
                assert proof['encoding']=='base64' and proof['path']==path
                content=base64.b64decode(proof['content'])
                assert content==payload(row['licenceFile'])
                assert digest(f'blob {len(content)}\0'.encode()+content,'sha1')==proof['sha']
            if row.get('licenceTransport')=='github-contents-api':
                assert row['licenceUrl']==f"https://api.github.com/repos/{slug}/contents/{path}?ref={row['resolvedCommit']}"
                raw=payload(row['licenceResponseFile']);assert digest(raw)==row['licenceResponseSha256'];verify_api(raw)
            else:
                assert row.get('licenceTransport') is None
                assert row['licenceUrl']==f"https://raw.githubusercontent.com/{slug}/{row['resolvedCommit']}/{path}"
            if 'commit' in source: assert source['commit']==row['resolvedCommit']
            else:
                ref='refs/tags/'+source['tag']
                refs={line.split()[1]:line.split()[0] for line in payload(row['refReceipt']).decode().splitlines()}
                assert refs.get(ref+'^{}',refs.get(ref))==row['resolvedCommit']
                if online:
                    fresh=subprocess.check_output(['git','ls-remote',source['git'],ref,ref+'^{}'],text=True,timeout=90)
                    refs={line.split()[1]:line.split()[0] for line in fresh.splitlines()}
                    assert refs.get(ref+'^{}',refs.get(ref))==row['resolvedCommit'], 'upstream tag drift'
            if online:
                raw=download(row['licenceUrl'])
                if row.get('licenceTransport')=='github-contents-api':verify_api(raw)
                else:assert digest(raw)==row['licenceSha256']
                online_count+=1
        else:
            assert row['downloadLocation']==source['http'] and row['licenseDeclared']=='NOASSERTION'
            def check_archive(raw):
                assert digest(raw)==row['archiveSha256']
                if row.get('licenceFile'):
                    with zipfile.ZipFile(io.BytesIO(raw)) as archive: assert archive.read(row['licencePath'])==payload(row['licenceFile'])
            if archive_root:
                check_archive((archive_root/row['archiveFile']).read_bytes())
            if online:
                check_archive(download(source['http']))
                online_count+=1
        if online:
            assert digest(download(row['specUrl']))==row['specSha256']
            online_count+=1
    wrappers=json.loads((folder/'wrapper-reverification.json').read_text())['records']
    old=json.loads((folder.parent/'native-wrapper-cache-inventory.json').read_text())['mappings']
    pub={r['id']:r for r in json.loads((folder.parent.parent/'pub/manifest.json').read_text())['records']}
    assert {r['package'] for r in wrappers}=={r['package'] for r in old}, 'wrapper coverage differs'
    for row in wrappers:
        previous=next(r for r in old if r['package']==row['package'])
        assert checks[row['package']]==row['locked_spec_checksum']==previous['locked_spec_checksum']
        assert pub['pub:'+row['package']]['version']==row['locked_pub_version']
        for f in row['files']:
            assert digest((folder.parent/f['path']).read_bytes())==f['sha256']
        if row.get('archiveSha256'):
            assert row['archiveSha256']==pub['pub:'+row['package']]['archiveSha256']
            if wrapper_archives:
                path=wrapper_archives/previous['authenticated_archive_filename']
                assert digest(path.read_bytes())==row['archiveSha256']
                with tarfile.open(path) as archive:
                    for f in previous['retained_file_archive_comparisons']:
                        assert archive.extractfile(f['archive_member']).read()==(folder.parent/f['evidence_path']).read_bytes()
        else:
            assert row['locked_git_revision']==previous['locked_git_revision']
            if online:
                for f in row['files']:
                    raw=download(f['url'])
                    assert digest(raw)==f['upstreamRawSha256']
                    assert raw.replace(b'\r\n',b'\n')==(folder.parent/f['path']).read_bytes().replace(b'\r\n',b'\n')
                    online_count+=1
    inventory=json.loads((folder/'unresolved-start-inventory.json').read_text())
    edges=inventory['lockedRootDependencyEdges']
    assert edges=={k:sorted(v) for k,v in sorted(graph.items())}, 'dependency graph differs from lock'
    recorded={r['name']:r for r in inventory['records']}
    for row in manifest['records']:assert row['packageRelationships']==recorded[row['name']]['packageRelationships']
    for row in inventory['records']:
        assert row['lockedSpecChecksum']==checks[row['name']]
        for link in row['packageRelationships']:
            path=link['podPath']
            assert path[0]==link['pubPackage'] and path[-1]==row['name']
            assert link['pubVersion']==pub['pub:'+link['pubPackage']]['version']
            assert all(b in edges[a] for a,b in zip(path,path[1:]))
    print(json.dumps({'registrySpecChecksums':len(manifest['records']), 'sourceLicencePayloads':sum('licenceFile' in r for r in manifest['records']), 'wrapperMappings':len(wrappers),'wrapperFiles':sum(len(r['files']) for r in wrappers),'onlinePayloadChecks':online_count,'nativeEvaluation':'NOT TESTED \u2014 MACOS/NATIVE ENVIRONMENT BLOCKER'}))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--online',action='store_true')
    parser.add_argument('--archive-root',type=Path)
    parser.add_argument('--wrapper-archives',type=Path)
    args=parser.parse_args()
    replay(Path(__file__).resolve().parent,args.archive_root,args.wrapper_archives,args.online)
