"""Replay exact Kotlin publisher artifacts and pinned upstream evidence.

This is evidence validation, not legal or release clearance. No network is
needed unless --replay is explicitly requested. The Dart importer independently
checks source/header scope and refuses unsupported declarations.
"""
from pathlib import Path
import argparse
import hashlib
import io
import json
import re
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = 'compliance/evidence/reconstruction-2026-10-09/kotlin-2026-10-13'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inspect_archive(data, source=False):
    entries, headers, notices, risks = [], [], [], []
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate ZIP entry')
        for n in sorted(names):
            if n.endswith('/'):
                continue
            if n.startswith('/') or '\\' in n or ':' in n or '..' in n.split('/'):
                raise ValueError('Unsafe ZIP entry')
            raw = archive.read(n)
            entries.append(dict(path=n, bytes=len(raw), sha256=digest(raw)))
            if re.search('license|licence|notice|copyright|copying|third.party', n, re.I):
                notices.append(n)
            if source and n.endswith(('.kt', '.java')):
                text = raw.decode('utf-8')
                header = text[:6000]
                headers.append(dict(path=n, apacheHeader='JetBrains' in header and ('Apache 2.0' in header or 'Apache License, Version 2.0' in header), boost='implementations derived from boost special math functions' in text))
            if n.endswith(('.bin', '.dex', '.so', '.jar', '.png', '.ttf', '.otf')):
                risks.append(dict(path=n, reason='Embedded binary payload requires separate exact source/build mapping'))
    return dict(entries=entries, sourceHeaders=headers, noticeNamedEntries=notices, risks=risks)


def verify(root=ROOT, replay=False, manifest=None):
    evidence = root / EVIDENCE
    manifest = manifest if manifest is not None else json.loads((evidence/'manifest.json').read_text(encoding='utf-8'))
    if manifest['schemaVersion'] != 1 or manifest['legalClearance'] is not False or manifest['releaseClearance'] is not False:
        raise ValueError('Unsupported manifest/clearance')
    graph_path = 'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11/resolved-graph.json'
    if manifest['graphPath'] != graph_path or digest((root/graph_path).read_bytes()) != manifest['graphSha256']:
        raise ValueError('Stale graph')
    graph = json.loads((root/graph_path).read_text(encoding='utf-8'))
    artifacts, coordinates = {}, set()
    for config in graph['configurations']:
        coordinates.update(n['id'] for n in config['components'])
        for item in config['artifacts']:
            artifacts.setdefault(item['module'], set()).add(item['sha256'])
    replayed = set()

    def read(item):
        path = item['path']
        if not re.fullmatch(r'blobs/[a-f0-9]{64}\.bin', path) or path != 'blobs/'+item['sha256']+'.bin':
            raise ValueError('Unsafe/content-address mismatch')
        data = (evidence/path).read_bytes()
        if digest(data) != item['sha256'] or len(data) != item['bytes']:
            raise ValueError('Payload hash/size mismatch')
        if replay and item.get('url') and item['url'] not in replayed:
            url = item['url']
            # API commit responses contain changeable transport metadata; verify
            # tag -> commit identity separately, all raw publisher bytes exactly.
            fresh = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'OLA-compliance-evidence'}), timeout=90).read()
            if '/commits/' in url:
                if json.loads(fresh)['sha'] != json.loads(data)['sha']:
                    raise ValueError('Upstream tag moved')
            elif digest(fresh) != item['sha256']:
                raise ValueError('Remote evidence drift')
            replayed.add(url)
        return data

    upstreams = {}
    for up in manifest['upstreams']:
        key = up['tag']
        if key in upstreams:
            raise ValueError('Duplicate upstream')
        repo = up['repository'].removeprefix('https://github.com/')
        if repo not in ['JetBrains/kotlin', 'Kotlin/kotlinx.coroutines'] or not re.fullmatch('[a-f0-9]{40}', up['commit']):
            raise ValueError('Unsupported upstream')
        if up['response']['url'] != f'https://api.github.com/repos/{repo}/commits/{key}' or json.loads(read(up['response']))['sha'] != up['commit']:
            raise ValueError('Tag/commit binding differs')
        files = {}
        for f in up['files']:
            p = f['sourcePath']
            if p in files or '..' in p.split('/') or f['url'] != f'https://raw.githubusercontent.com/{repo}/{up["commit"]}/{p}':
                raise ValueError('Upstream URL/scope mismatch')
            files[p] = read(f)
        licence = files['license/LICENSE.txt' if repo == 'JetBrains/kotlin' else 'LICENSE.txt']
        if b'Apache License' not in licence or b'END OF TERMS AND CONDITIONS' not in licence:
            raise ValueError('Incomplete licence')
        if (b'Kotlin Compiler' if repo == 'JetBrains/kotlin' else b'kotlinx.coroutines library') not in files['license/NOTICE.txt']:
            raise ValueError('NOTICE scope missing')
        upstreams[key] = (up, files)
    records = {r['coordinate']:r for r in manifest['records']}
    if len(records) != len(manifest['records']) or sorted(records) != manifest['cohortCoordinates']:
        raise ValueError('Duplicate/incomplete cohort')
    for coord, row in records.items():
        g, a, v = coord.split(':')
        if coord not in coordinates or g not in ['org.jetbrains.kotlin','org.jetbrains.kotlinx'] or row['id'] != 'maven:'+g+':'+a or row['version'] != v:
            raise ValueError('Unselected coordinate/version')
        key = 'v'+v if g=='org.jetbrains.kotlin' else v
        up, upstream_files = upstreams[key]
        if row['upstreamKey'] != key or row['upstreamRepository'] != up['repository']:
            raise ValueError('Wrong upstream release')
        if row['legalClearance'] is not False or row['releaseClearance'] is not False or not row['conditions']:
            raise ValueError('Unsupported clearance/conditions')
        stem=a+'-'+v
        base='https://repo.maven.apache.org/maven2/'+g.replace('.','/')+'/'+a+'/'+v+'/'
        supplied={};roles=[]
        for f in row['files']:
            allowed={'pom':stem+'.pom','module':stem+'.module','source':stem+'-sources.jar','binary':stem+'.jar','reference-binary':stem+'.jar'}
            name=f['filename'];role=f['role']
            if name in supplied or allowed.get(role)!=name or f['url']!=base+name:
                raise ValueError('Publisher/role/version mismatch')
            supplied[name]=read(f);roles.append(role)
        bom=a.endswith('-bom')
        if roles.count('pom')!=1 or roles.count('source')!=(0 if bom else 1) or roles.count('module')>1:
            raise ValueError('Missing exact source/POM')
        if bom and roles!=['pom'] or not bom and roles.count('binary')+roles.count('reference-binary')!=1:
            raise ValueError('Metadata/runtime roles differ')
        if 'reference-binary' in roles and (a!='kotlinx-coroutines-core' or artifacts.get(coord)):
            raise ValueError('Unsupported reference artifact')
        hashes={f['sha256'] for f in row['files'] if f['role']=='binary'}
        if hashes!=artifacts.get(coord,set()):
            raise ValueError('Selected graph binary differs')
        ns={'m':'http://maven.apache.org/POM/4.0.0'};pom=ET.fromstring(supplied[stem+'.pom'])
        if ':'.join(pom.findtext('m:'+k,namespaces=ns) for k in ['groupId','artifactId','version'])!=coord or pom.findtext('m:scm/m:url',namespaces=ns)!=row['upstreamRepository']:
            raise ValueError('POM identity/upstream differs')
        if bom and pom.findtext('m:packaging',namespaces=ns)!='pom':
            raise ValueError('BOM is not metadata-only')
        licences=pom.findall('m:licenses/m:license',ns)
        if len(licences)!=1 or licences[0].findtext('m:name',namespaces=ns) not in ['The Apache Software License, Version 2.0','The Apache License, Version 2.0'] or licences[0].findtext('m:url',namespaces=ns) not in ['http://www.apache.org/licenses/LICENSE-2.0.txt','https://www.apache.org/licenses/LICENSE-2.0.txt']:
            raise ValueError('POM licence differs')
        if b'published-with-gradle-metadata' in supplied[stem+'.pom'] and stem+'.module' not in supplied:
            raise ValueError('Published Gradle module metadata missing')
        if stem+'.module' in supplied:
            module=json.loads(supplied[stem+'.module']);identity=module['component']
            declared=':'.join(identity.get(k,'') for k in ['group','module','version'])
            if declared!=coord:
                parentrow=records.get(declared)
                if parentrow is None or not identity.get('url'):
                    raise ValueError('Module identity mismatch')
                parentfile=next(f for f in parentrow['files'] if f['role']=='module')
                parent=json.loads(read(parentfile));pi=parent['component']
                childurl=base+stem+'.module'
                if ':'.join(pi.get(k,'') for k in ['group','module','version'])!=declared or urllib.parse.urljoin(childurl,identity['url'])!=parentfile['url']:
                    raise ValueError('Unbound parent module')
                links=[var['available-at'] for var in parent['variants'] if 'available-at' in var]
                if not any(':'.join(link.get(k,'') for k in ['group','module','version'])==coord and urllib.parse.urljoin(parentfile['url'],link['url'])==childurl for link in links):
                    raise ValueError('Missing reciprocal publication mapping')
            for variant in module.get('variants',[]):
                for f in variant.get('files',[]):
                    if f['name'] in supplied:
                        data=supplied[f['name']]
                        for alg in ['sha256','sha512','sha1','md5']:
                            if alg in f and hashlib.new(alg,data).hexdigest()!=f[alg]:
                                raise ValueError('Module artifact checksum mismatch')
        scans={f['filename']:inspect_archive(supplied[f['filename']],f['role']=='source') for f in row['files'] if f['filename'].endswith('.jar')}
        if scans!=json.loads(read(row['audit']))['archives']:
            raise ValueError('Archive scope/NOTICE inventory drift')
        used=[];boost=False
        for name,scan in scans.items():
            for source in scan['sourceHeaders']:
                boost|=source['boost']
                if source['apacheHeader'] and not source['boost']:
                    continue
                mappings=[m for m in row['sourceMappings'] if m['archive']==name and m['entry']==source['path']]
                if len(mappings)!=1:
                    raise ValueError('Missing exact source mapping')
                m=mappings[0];entry=next(e for e in scan['entries'] if e['path']==source['path'])
                if m['sha256']!=entry['sha256'] or digest(upstream_files[m['upstreamPath']])!=entry['sha256']:
                    raise ValueError('Source/upstream mismatch')
                used.append(m)
        if len(used)!=len(row['sourceMappings']):
            raise ValueError('Unused source mapping')
        if boost and (b'Boost Software License - Version 1.0' not in upstream_files['license/third_party/boost_LICENSE.txt'] or b'libraries/stdlib/jvm/src/kotlin/util/MathJVM.kt' not in upstream_files['license/README.md']):
            raise ValueError('Boost scope missing')
        if a in ['kotlin-stdlib','kotlin-stdlib-common']:
            for p in ['license/third_party/gwt_license.txt','license/third_party/guava_license.txt']:
                if b'END OF TERMS AND CONDITIONS' not in upstream_files[p]:
                    raise ValueError('Third-party licence missing')
        risks=[r for s in scans.values() for r in s['risks']]
        expected='NOASSERTION' if risks else 'Apache-2.0 AND BSL-1.0' if boost else 'Apache-2.0'
        if row['licenseDeclared']!=expected or row['classification']!=('Needs Verification' if risks else 'Verified with conditions'):
            raise ValueError('Unsupported declaration/scope')
    return dict(reviewed=len(records),resolved=sum(r['licenseDeclared']!='NOASSERTION' for r in records.values()),remaining=sum(r['licenseDeclared']=='NOASSERTION' for r in records.values()),replayedUrls=len(replayed))


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--replay',action='store_true');args=parser.parse_args()
    print(json.dumps(verify(replay=args.replay),sort_keys=True))
