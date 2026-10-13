"""Replay exact gRPC Java evidence. Technical declarations are not release clearance."""
from pathlib import Path
import argparse, hashlib, io, json, re, urllib.request, xml.etree.ElementTree as ET, zipfile
ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = 'compliance/evidence/reconstruction-2026-10-09/grpc-java-2026-10-13'
GRAPH = 'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11/resolved-graph.json'
GENERATED = '''/**
 * Automatically generated file. DO NOT MODIFY
 */
package io.grpc.android;

public final class BuildConfig {
  public static final boolean DEBUG = false;
  public static final String LIBRARY_PACKAGE_NAME = "io.grpc.android";
  public static final String BUILD_TYPE = "release";
}
'''
REQUIRED_CONDITIONS = ['Technical evidence only; not legal/release clearance or reproducible binary rebuild.', 'Preserve upstream LICENSE, NOTICE.txt and applicable source copyright/modification notices. Repository-wide NOTICE references outside this cohort are context, not evidence of inclusion.', 'Graph runtime distribution is not proof of release-APK inclusion; dependencies retain separate classifications. Production Android and iOS/native verification remain incomplete.']

def digest(b): return hashlib.sha256(b).hexdigest()
def require(ok, message):
    if not ok: raise ValueError(message)
def unzip(data):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names=z.namelist(); require(len(names)==len(set(names)), 'duplicate ZIP entry')
        require(all(not n.startswith('/') and '\\' not in n and ':' not in n and '..' not in n.split('/') for n in names),'unsafe ZIP path')
        return {n:z.read(n) for n in sorted(names) if not n.endswith('/')}
def audit_sources(source, binary, upstream, module):
    sources=unzip(source); payload=unzip(binary); entries=[]; mappings=[]; risks=[]
    prefix=module+'/src/main/java/'
    for n,b in sources.items():
        if n.endswith('.java'):
            possible=[prefix+n]
            if module=='api' and b'sourceSets.context.allSource' in upstream['api/build.gradle']:possible.append('api/src/context/java/'+n)
            if module=='okhttp':possible.append('okhttp/third_party/okhttp/main/java/'+n)
            matches=[p for p in possible if upstream.get(p)==b]
            generated=(module=='android' and n=='io/grpc/android/BuildConfig.java' and b.decode()==GENERATED
                       and "namespace 'io.grpc.android'" in upstream['android/build.gradle'].decode()
                       and "singleVariant('release')" in upstream['android/build.gradle'].decode())
            mappings.append(dict(path=n,sha256=digest(b),upstreamPaths=matches,generatedMetadata=generated))
            if not matches and not generated:risks.append('Source not mapped to exact upstream: '+n)
            if not generated and b'Apache License, Version 2.0' not in b[:6000]:risks.append('Unverified source licence header: '+n)
            if re.search(rb'copied from',b,re.I):risks.append('Copied third-party source lacks separately scoped evidence: '+n)
            if b'Apache Software Foundation' in b[:6000]:risks.append('ASF source refers to separately scoped NOTICE not established: '+n)
        elif n.startswith('META-INF/services/') and upstream.get(module+'/src/main/resources/'+n)==b:pass
        elif n!='META-INF/MANIFEST.MF':risks.append('Unreviewed source resource: '+n)
    def scan(files, parent=''):
        for n,b in files.items():
            path=parent+n; entries.append(dict(path=path,bytes=len(b),sha256=digest(b)))
            if n=='classes.jar' and module=='android' and not parent:
                scan(unzip(b),path+'!');continue
            if n.endswith('.class'):
                outer=n.split('$')[0].removesuffix('.class')+'.java'
                if outer not in sources:risks.append('Binary class lacks published source file: '+path)
            elif n=='META-INF/MANIFEST.MF':pass
            elif n.startswith('META-INF/services/'):
                for line in b.decode().splitlines():
                    line=line.split('#')[0].strip()
                    if line and line.split('$')[0].replace('.','/')+'.java' not in sources:risks.append('Service provider lacks source: '+path)
            elif module=='android' and not parent and n=='R.txt' and not b:pass
            elif module=='android' and not parent and n in ['AndroidManifest.xml','META-INF/com/android/build/gradle/aar-metadata.properties']:pass
            elif module=='android' and not parent and n=='proguard.txt' and b==upstream.get('android/proguard-rules.txt'):pass
            else:risks.append('Unreviewed binary resource: '+path)
    scan(payload)
    return dict(sourceEntries=[dict(path=n,bytes=len(b),sha256=digest(b)) for n,b in sources.items()],binaryEntries=entries,sourceMappings=mappings,risks=sorted(risks))
def verify(root=ROOT,replay=False,manifest=None):
    root=Path(root);e=root/EVIDENCE;m=manifest if manifest is not None else json.loads((e/'manifest.json').read_text(encoding='utf-8'))
    require(m['schemaVersion']==1 and m['legalClearance'] is False and m['releaseClearance'] is False,'manifest clearance/schema')
    require(m['graphPath']==GRAPH and digest((root/GRAPH).read_bytes())==m['graphSha256'],'stale graph')
    seen=set()
    def read(f):
        require(re.fullmatch(r'blobs/[a-f0-9]{64}\.bin',f['path']) and f['path']=='blobs/'+f['sha256']+'.bin','unsafe blob')
        b=(e/f['path']).read_bytes();require(digest(b)==f['sha256'] and len(b)==f['bytes'],'payload hash')
        if replay and f.get('url') and f['url'] not in seen:
            fresh=urllib.request.urlopen(urllib.request.Request(f['url'],headers={'User-Agent':'OLA-compliance-evidence'}),timeout=90).read()
            require(json.loads(fresh)['sha']==json.loads(b)['sha'] if '/commits/' in f['url'] else digest(fresh)==digest(b),'remote drift');seen.add(f['url'])
        return b
    u=m['upstream'];commit=u['commit'];version=u['version']
    require(re.fullmatch('[a-f0-9]{40}',commit) and re.fullmatch(r'\d+\.\d+\.\d+',version),'invalid revision')
    require(u['repository']=='https://github.com/grpc/grpc-java' and u['tag']=='v'+version,'upstream identity')
    require(u['response']['url']=='https://api.github.com/repos/grpc/grpc-java/commits/v'+version and json.loads(read(u['response']))['sha']==commit,'tag commit binding')
    require(u['archive']['url']=='https://codeload.github.com/grpc/grpc-java/zip/'+commit,'source archive URL')
    raw=unzip(read(u['archive']));prefix='grpc-java-'+commit+'/'
    require(all(n.startswith(prefix) for n in raw),'upstream archive root')
    upstream={n[len(prefix):]:b for n,b in raw.items()}
    require(('version = "'+version+'" // CURRENT_GRPC_VERSION').encode() in upstream['build.gradle'],'upstream release version')
    require(b'Apache License' in upstream['LICENSE'] and b'END OF TERMS AND CONDITIONS' in upstream['LICENSE'],'complete Apache text')
    require(b'Copyright 2014 The gRPC Authors' in upstream['NOTICE.txt'] and b'okhttp/third_party/okhttp/LICENSE' in upstream['NOTICE.txt'],'missing scoped NOTICE')
    require(b'END OF TERMS AND CONDITIONS' in upstream['okhttp/third_party/okhttp/LICENSE'],'missing vendored OkHttp licence')
    graph=json.loads((root/GRAPH).read_text());hashes={};coordinates=set();edges={}
    for cfg in graph['configurations']:
        for c in cfg['components']:
            coordinates.add(c['id']);edges.setdefault(c['id'],set()).update(d['selected'] for d in c['dependencies'] if not d.get('constraint'))
        for a in cfg['artifacts']:hashes.setdefault(a['module'],set()).add(a['sha256'])
    cohort=sorted(c for c in coordinates if c.startswith('io.grpc:'))
    require(sorted(r['coordinate'] for r in m['records'])==cohort==m['cohortCoordinates'],'cohort mismatch')
    out=[]
    for r in m['records']:
        coord=r['coordinate'];g,a,v=coord.split(':');module=a.removeprefix('grpc-');stem=a+'-'+v
        require(g=='io.grpc' and v==version and r['id']=='maven:'+g+':'+a and r['version']==v and r['module']==module,'wrong module/release')
        require(r['legalClearance'] is False and r['releaseClearance'] is False and r['conditions'][:3]==REQUIRED_CONDITIONS and all(isinstance(c,str) and c.strip() for c in r['conditions']),'clearance/conditions')
        require(r['relationship']=='transitive' and r['distributed'] is True,'scope differs')
        plugins=[]
        for p in sorted(k for k in edges if k.startswith('project :') and k!='project :app'):
            todo=[p];visited=set()
            while todo:
                n=todo.pop()
                if n in visited:continue
                visited.add(n);todo.extend(edges.get(n,[]))
            if coord in visited:plugins.append(p)
        require(r['flutterPluginAncestors']==plugins,'plugin mapping differs')
        files={f['role']:f for f in r['files']};require(len(files)==len(r['files']) and set(files)=={'pom','source','binary'},'missing/duplicate publisher evidence')
        expected=dict(pom=stem+'.pom',source=stem+'-sources.jar',binary=stem+('.aar' if module=='android' else '.jar'))
        data={}
        for role,f in files.items():
            require(f['filename']==expected[role] and f['url']=='https://repo.maven.apache.org/maven2/io/grpc/'+a+'/'+v+'/'+expected[role],'publisher release mismatch');data[role]=read(f)
        require(hashes.get(coord)=={files['binary']['sha256']},'graph binary mismatch')
        pom=ET.fromstring(data['pom']);ns={'m':'http://maven.apache.org/POM/4.0.0'}
        require(':'.join(pom.findtext('m:'+k,namespaces=ns) or '' for k in ['groupId','artifactId','version'])==coord,'POM identity')
        licenses=pom.findall('m:licenses/m:license',ns)
        require(len(licenses)==1 and licenses[0].findtext('m:name',namespaces=ns)=='Apache 2.0' and licenses[0].findtext('m:url',namespaces=ns)=='https://opensource.org/licenses/Apache-2.0','POM licence')
        require(pom.findtext('m:scm/m:url',namespaces=ns)==u['repository'],'POM source repository')
        require(b'published-with-gradle-metadata' not in data['pom'],'unhandled Gradle metadata')
        require((pom.findtext('m:packaging',namespaces=ns) or 'jar')==('aar' if module=='android' else 'jar'),'packaging mismatch')
        require(module+'/build.gradle' in upstream,'module build missing')
        audit=audit_sources(data['source'],data['binary'],upstream,module)
        require(json.loads(read(r['audit']))==audit,'recomputed archive audit mismatch')
        require(r['risksSummary']==audit['risks'],'risk summary differs from recomputed audit')
        expected_license='NOASSERTION' if audit['risks'] else 'Apache-2.0'
        require(r['licenseDeclared']==expected_license and r['classification']==('Needs Verification' if audit['risks'] else 'Verified with conditions'),'unsupported classification')
        out.append(dict(coordinate=coord,licenseDeclared=expected_license,risks=audit['risks']))
    return dict(reviewed=len(out),resolved=sum(r['licenseDeclared']!='NOASSERTION' for r in out),remaining=sum(r['licenseDeclared']=='NOASSERTION' for r in out),replayedUrls=len(seen),records=out)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--replay',action='store_true');args=p.parse_args();print(json.dumps(verify(replay=args.replay),indent=2))
