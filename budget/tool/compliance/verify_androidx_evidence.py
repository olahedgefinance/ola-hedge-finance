"""Replay exact AndroidX publisher artifacts; never infer clearance by namespace."""
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
EVIDENCE = 'compliance/evidence/reconstruction-2026-10-09/androidx-2026-10-11'
GOOGLE = 'https://dl.google.com/dl/android/maven2/'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inspect_archive(data, source=False):
    """Deterministic inventory, not a general-purpose licence classifier."""
    entries, headers, notices, risks, lineage = [], [], [], [], []

    def walk(payload, prefix='', depth=0):
        if depth > 4:
            raise ValueError('Excessive nested archive depth')
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            names = archive.namelist()
            if len(names) != len(set(names)):
                raise ValueError('Duplicate ZIP entries')
            for item in sorted(archive.infolist(), key=lambda i: i.filename):
                if item.is_dir():
                    continue
                name = item.filename
                if name.startswith('/') or '\\' in name or ':' in name or '..' in name.split('/'):
                    raise ValueError('Unsafe ZIP entry')
                value = archive.read(item)
                path = prefix + name
                entries.append(dict(path=path,bytes=len(value),sha256=digest(value)))
                if re.search(r'license|licence|notice|copying|copyright|third.party', name, re.I):
                    notices.append(path)
                if name.endswith(('.png','.jpg','.jpeg','.webp','.ttf','.otf','.so')):
                    risks.append(dict(path=path,reason='Binary resource has no exact source/licence mapping in this review'))
                if name.endswith('.dex'):
                    risks.append(dict(path=path,reason='Bundled DEX/tooling implementations require their own source/licence scope review'))
                if name.endswith('.class') and (re.search(r'(^|/)(protobuf|external|shaded|repackaged)/', name) or name.startswith(('kotlin/','kotlinx/','org/jetbrains/','org/intellij/'))):
                    risks.append(dict(path=path,reason='Embedded third-party or relocated implementation; top-level POM is insufficient'))
                if source and name.endswith(('.java','.kt','.aidl','.proto','.c','.cpp','.h','.js')):
                    text = value.decode('utf-8', errors='replace')
                    apache = 'Licensed under the Apache License, Version 2.0' in text[:6000] or 'SPDX-License-Identifier: Apache-2.0' in text[:6000]
                    # Empty files/package-only declarations contain no implementation.
                    noncomment = re.sub(r'/\*.*?\*/|//[^\n]*', '', text, flags=re.S).strip()
                    declaration_only = bool(re.fullmatch(r'(?:package\s+[\w.]+\s*;\s*)?(?:parcelable\s+\w+\s*;\s*)?', noncomment))
                    headers.append(dict(path=path,apacheHeader=apache,empty=not value,declarationOnly=declaration_only))
                    if not apache and not declaration_only and value:
                        risks.append(dict(path=path,reason='Source implementation lacks a directly matched Apache header; needs separate review'))
                    if '/external/' in name:
                        risks.append(dict(path=path,reason='Vendored external source refers to separately scoped upstream evidence'))
                    for match in re.finditer(r'(?im)^.*(?:cloned from|copied from|versions of Guava|adapted from|github.com/Kotlin/kotlinx.collections).*$' ,text):
                        lineage.append(dict(path=path,text=match.group(0).strip()))
                if name.endswith('.jar'):
                    walk(value, path+'!', depth+1)
    walk(data)
    return dict(entries=entries,sourceHeaders=headers,noticeNamedEntries=notices,risks=risks,lineage=lineage)


def verify(root=ROOT, replay=False):
    evidence = root / EVIDENCE
    manifest = json.loads((evidence/'manifest.json').read_text(encoding='utf-8'))
    graphbytes = (root/manifest['graphPath']).read_bytes()
    if digest(graphbytes) != manifest['graphSha256']:
        raise ValueError('Stale graph')
    graph = json.loads(graphbytes)
    artifacts = {}
    coordinates = set()
    for config in graph['configurations']:
        coordinates.update(n['id'] for n in config['components'])
        for item in config['artifacts']:
            artifacts.setdefault(item['module'], set()).add(item['sha256'])
    def read(item):
        path = item['path']
        if not re.fullmatch(r'blobs/[a-f0-9]{64}\.bin', path):
            raise ValueError('Unsafe payload path')
        data = (evidence/path).read_bytes()
        if digest(data) != item['sha256'] or len(data) != item['bytes']:
            raise ValueError('Payload hash/size mismatch')
        if path != 'blobs/'+item['sha256']+'.bin':
            raise ValueError('Payload content address differs')
        return data
    licence = read(manifest['sharedLicence'])
    if b'Apache License' not in licence or b'Version 2.0' not in licence:
        raise ValueError('Missing complete shared licence')
    seen = set()
    for row in manifest['records']:
        coordinate = row['coordinate']
        if coordinate in seen or coordinate not in coordinates or not coordinate.startswith('androidx.'):
            raise ValueError('Duplicate/unselected/out-of-scope coordinate')
        seen.add(coordinate)
        group, artifact, version = coordinate.split(':')
        expectedbase = GOOGLE+group.replace('.','/')+'/'+artifact+'/'+version+'/'
        if row['id'] != 'maven:'+group+':'+artifact or row['version'] != version:
            raise ValueError('Record identity mismatch')
        stem = artifact+'-'+version
        roles = [f['role'] for f in row['files']]
        if roles.count('pom') != 1 or roles.count('source') != 1 or roles.count('module') > 1:
            raise ValueError('Missing or duplicate exact source/POM')
        names = set()
        payloads = {}
        for f in row['files']:
            name, role = f['filename'], f['role']
            if name in names:
                raise ValueError('Duplicate publisher file')
            names.add(name)
            allowed = {'pom':[stem+'.pom'], 'source':[stem+'-sources.jar'],
                       'module':[stem+'.module'], 'binary':[stem+'.aar',stem+'.jar']}
            if role not in allowed or name not in allowed[role]:
                raise ValueError('Role or release filename mismatch')
            data = read(f)
            if f['url'] != expectedbase+f['filename'] or '/' in f['filename'] or not f['filename'].startswith(artifact+'-'+version):
                raise ValueError('Publisher/version URL mismatch')
            payloads[f['role']] = data if f['role'] != 'binary' else payloads.get('binary', [])+[data]
            if replay:
                if digest(urllib.request.urlopen(f['url'],timeout=60).read()) != f['sha256']:
                    raise ValueError('Publisher artifact drift')
        ns={'m':'http://maven.apache.org/POM/4.0.0'}
        pom=ET.fromstring(payloads['pom'])
        if ':'.join(pom.findtext('m:'+k,namespaces=ns) for k in ['groupId','artifactId','version']) != coordinate:
            raise ValueError('POM coordinate mismatch')
        licences=pom.findall('m:licenses/m:license',ns)
        if len(licences)!=1 or licences[0].findtext('m:name',namespaces=ns)!='The Apache Software License, Version 2.0':
            raise ValueError('POM licence scope changed')
        if licences[0].findtext('m:url',namespaces=ns) not in ['http://www.apache.org/licenses/LICENSE-2.0.txt','https://www.apache.org/licenses/LICENSE-2.0.txt']:
            raise ValueError('POM licence URL mismatch')
        scm=pom.findtext('m:scm/m:connection',namespaces=ns)
        if scm!='scm:git:https://android.googlesource.com/platform/frameworks/support':
            raise ValueError('POM upstream mismatch')
        hashes={digest(b) for b in payloads.get('binary',[])}
        if hashes != artifacts.get(coordinate,set()):
            raise ValueError('Binary graph binding mismatch')
        if 'module' in payloads:
            module=json.loads(payloads['module']);identity=module['component']
            if [identity.get(k) for k in ['group','module','version']] != [group,artifact,version]:
                # Gradle multiplatform publication may identify its parent component.
                parentcoord=':'.join(identity.get(k,'') for k in ['group','module','version'])
                parents=[r for r in manifest['records'] if r['coordinate']==parentcoord]
                childfile=next(f for f in row['files'] if f['role']=='module')
                if len(parents)!=1 or not identity.get('url'):
                    raise ValueError('Module identity mismatch')
                parentfile=next(f for f in parents[0]['files'] if f['role']=='module')
                parent=json.loads(read(parentfile))
                pi=parent['component']
                if ':'.join(pi.get(k,'') for k in ['group','module','version'])!=parentcoord or urllib.parse.urljoin(childfile['url'],identity['url'])!=parentfile['url']:
                    raise ValueError('Unbound parent module')
                links=[variant['available-at'] for variant in parent['variants'] if 'available-at' in variant]
                if not any([link.get(k) for k in ['group','module','version']]==[group,artifact,version] and urllib.parse.urljoin(parentfile['url'],link['url'])==childfile['url'] for link in links):
                    raise ValueError('Missing reciprocal publication mapping')
            supplied={f['filename']:f for f in row['files']}
            for variant in module.get('variants',[]):
                for f in variant.get('files',[]):
                    if f['name'] in supplied:
                        raw=read(supplied[f['name']])
                        for algorithm in ['sha256','sha512','sha1','md5']:
                            if algorithm in f and hashlib.new(algorithm,raw).hexdigest()!=f[algorithm]:
                                raise ValueError('Module artifact checksum mismatch')
        scans={f['filename']:inspect_archive(read(f),f['role']=='source') for f in row['files'] if f['role'] in ['source','binary']}
        audited=json.loads(read(row['audit']))
        if scans!=audited['archives']:
            raise ValueError('Archive audit/notice inventory drift')
        risks=[risk for scan in scans.values() for risk in scan['risks']]
        if row['legalClearance'] or row['releaseClearance'] or not row['conditions']:
            raise ValueError('Unsupported clearance or missing conditions')
        if row['licenseDeclared']=='Apache-2.0':
            if risks or row['classification']!='Verified with conditions':
                raise ValueError('Over-classified incomplete scope')
        elif row['licenseDeclared']!='NOASSERTION' or row['classification']!='Needs Verification':
            raise ValueError('Unsupported classification')
    if sorted(seen)!=manifest['cohortCoordinates']:
        raise ValueError('Cohort coverage differs')
    return dict(reviewed=len(seen),resolved=sum(r['licenseDeclared']=='Apache-2.0' for r in manifest['records']),remaining=sum(r['licenseDeclared']=='NOASSERTION' for r in manifest['records']))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--replay',action='store_true');args=parser.parse_args()
    print(json.dumps(verify(replay=args.replay),sort_keys=True))
