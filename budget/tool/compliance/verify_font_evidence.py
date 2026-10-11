"""Replay exact font bytes. Offline inventory is not legal or native-release approval."""
import argparse, hashlib, json, struct, tarfile, zipfile, io, urllib.request, re
from pathlib import Path
REL='compliance/evidence/reconstruction-2026-10-09/fonts-2026-10-11'
def digest(b): return hashlib.sha256(b).hexdigest()
def require(ok, message):
    if not ok: raise ValueError(message)
def safe(p):
    require(bool(p) and not p.startswith('/') and ':' not in p and chr(92) not in p and all(x not in ('','..') for x in p.split('/')), 'unsafe path')
    return p
def sfnt(b):
 n=struct.unpack_from('>H',b,4)[0];tables={}
 for i in range(n):
  t,c,o,l=struct.unpack_from('>4sIII',b,12+16*i);tables[t.decode()]=(o,l)
 o,l=tables['name'];_,n,s=struct.unpack_from('>HHH',b,o);names={}
 for i in range(n):
  p,e,lang,nid,ln,off=struct.unpack_from('>HHHHHH',b,o+6+12*i)
  raw=b[o+s+off:o+s+off+ln]
  try: value=raw.decode('utf-16-be' if p in (0,3) else 'mac_roman')
  except UnicodeError:continue
  names.setdefault(str(nid),[])
  if value not in names[str(nid)]:names[str(nid)].append(value)
 return {'names':names,'weight':struct.unpack_from('>H',b,tables['OS/2'][0]+4)[0] if 'OS/2' in tables else None}

def dependency_context(m, lock, tool_version, pin, observed):
    block=re.search(r'^  material_symbols_icons:\n(.*?)(?=^  [A-Za-z_]+:)',lock,re.M|re.S)
    require(block is not None,'package absent from lock')
    text=block.group(1)
    release=m['_release']
    require('version: "'+release['version']+'"' in text and 'sha256: "'+release['archive_sha256']+'"' in text and 'source: hosted' in text and 'dependency: "direct main"' in text,'locked package mismatch')
    require(tool_version==m['flutterSource']['version'],'SDK version mismatch')
    fonts=m['dependencyFonts'];keys=[(x['componentId'],x['path']) for x in fonts]
    require(len(keys)==len(set(keys)),'duplicate dependency font')
    symbols=[x for x in fonts if x['componentId']=='pub:material_symbols_icons']
    require(len(symbols)==6 and all(x['archiveSha256']==release['archive_sha256'] and x['archiveUrl']==release['archive_url'] for x in symbols),'package archive mismatch/coverage')
    sdk=[x for x in fonts if x['componentId']=='tool:flutter-sdk']
    require(len(sdk)==1 and sdk[0]['archiveUrl']=='https://storage.googleapis.com/'+pin.strip(),'SDK pin mismatch')
    require(sdk[0]['licenseDeclared']=='CC-BY-4.0' and all(x['licenseDeclared']=='Apache-2.0' for x in symbols),'font licence mapping mismatch')
    expected={f['path'].removeprefix('budget/') for r in m['records'] for f in r['files']}
    for x in fonts:
        if x['distribution']=='runtime-distributed':expected.add(('fonts/' if x['componentId']=='tool:flutter-sdk' else 'packages/material_symbols_icons/')+x['path'])
    actual={f['asset'] for family in observed for f in family['fonts']}
    require(actual==expected,'runtime font manifest coverage mismatch')

def verify(root):
    folder=root/REL; m=json.loads((folder/'manifest.json').read_text(encoding='utf8'))
    require(m['schemaVersion']==1,'schema mismatch')
    for f in m['retainedFiles']:
        b=(folder/safe(f['path'])).read_bytes()
        require(len(b)==f['bytes'] and digest(b)==f['sha256'],'retained hash mismatch')
    observed=set()
    for r in m['records']:
        require(r['legalClearance'] is False and r['releaseClearance'] is False,'clearance forbidden')
        for f in r['files']:
            p=safe(f['path']);require(p not in observed,'duplicate font');observed.add(p)
            b=(root/p).read_bytes();require(digest(b)==f['sha256'] and len(b)==f['bytes'],'bundled hash mismatch')
            meta=sfnt(b);require(meta['names']==f['names'] and meta['weight']==f['weight'],'metadata mismatch')
        if r['proof'] is None:require(r['licenseDeclared']=='NOASSERTION','unsupported promotion')
    actual={p.relative_to(root).as_posix() for p in (root/'budget/assets').rglob('*') if p.suffix.lower() in ('.ttf','.otf','.woff','.woff2','.ttc')}
    require(actual==observed,'font set differs')
    m['_release']=json.loads((folder/'dependencies/material-symbols-release.json').read_text(encoding='utf8'))
    tool=json.loads((root/'compliance/components/non_pub_components.json').read_text(encoding='utf8'))
    version=next(x['version'] for x in tool['components'] if x['id']=='tool:flutter-sdk')
    pin=(folder/m['flutterSource']['pinPath']).read_text(encoding='utf8')
    observed=json.loads((folder/'font-manifest.observed.json').read_text(encoding='utf8'))
    dependency_context(m,(root/'budget/pubspec.lock').read_text(encoding='utf8'),version,pin,observed)
    return m

def validate_archive(raw, rows, kind):
    require(bool(rows),'empty archive record set')
    require(all(digest(raw)==r['archiveSha256'] for r in rows),'archive digest mismatch')
    if kind=='zip':
        with zipfile.ZipFile(io.BytesIO(raw)) as z: payload={r['path']:z.read(safe(r['path'])) for r in rows}
    else:
        with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as t:
            font_members=[x.name for x in t.getmembers() if x.isfile() and x.name.lower().endswith(('.ttf','.otf','.woff','.woff2','.ttc'))]
            require(len(font_members)==len(set(font_members)) and set(font_members)=={r['path'] for r in rows},'package font coverage mismatch')
            payload={}
            for r in rows:
                member=t.getmember(safe(r['path']));require(member.isfile(),'not regular archive file')
                payload[r['path']]=t.extractfile(member).read()
    for r in rows:
        b=payload[r['path']];require(digest(b)==r['sha256'] and len(b)==r['bytes'],'archive font mismatch')
        meta=sfnt(b);require(meta['names']==r['names'] and meta['weight']==r['weight'],'archive metadata mismatch')
    return payload

def replay(root, archives=None):
    m=verify(root);folder=root/REL
    def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'OLA-exact-font-evidence'}),timeout=90).read()
    require(get(m['flutterSource']['pinUrl'])==(folder/m['flutterSource']['pinPath']).read_bytes(),'official SDK font pin changed')
    for r in m['records']:
        if r['proof']:
            for match in r['proof']['matches']:
                raw=get(match['url']);require(raw==(root/match['path']).read_bytes(),'upstream font mismatch')
            for item in r['proof']['licenceSources']:
                url='https://raw.githubusercontent.com/googlefonts/dm-fonts/'+r['proof']['commit']+'/'+item['upstreamPath']
                require(get(url)==(folder/item['path']).read_bytes(),'upstream licence mismatch')
    for cid,name,kind in [('pub:material_symbols_icons','material_symbols_icons-4.2768.0.tar.gz','tar'),('tool:flutter-sdk','material-fonts.zip','zip')]:
        rows=[r for r in m['dependencyFonts'] if r['componentId']==cid]
        raw=(archives/name).read_bytes() if archives else get(rows[0]['archiveUrl'])
        validate_archive(raw,rows,kind)
        if kind=='zip':
            with zipfile.ZipFile(io.BytesIO(raw)) as z: notice=z.read('MaterialIcons_LICENSE.txt')
        else:
            with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as t: notice=t.extractfile('LICENSE').read()
        require(notice==(folder/rows[0]['licensePath']).read_bytes(),'dependency licence mismatch')
    return {'bundledFonts':sum(len(r['files']) for r in m['records']),'dependencyFonts':len(m['dependencyFonts']),'exactApplicationFamilies':sum(r['proof'] is not None for r in m['records']),'legalClearance':False}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--replay',action='store_true');p.add_argument('--archives',type=Path);a=p.parse_args()
    root=Path(__file__).resolve().parents[3]
    result=replay(root,a.archives) if a.replay else {'families':len(verify(root)['records']),'mode':'offline byte/metadata verification'}
    print(json.dumps(result,indent=2))
