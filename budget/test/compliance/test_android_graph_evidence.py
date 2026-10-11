from pathlib import Path
import hashlib,json,unittest,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[3]
E=ROOT/'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11'
class AndroidEvidenceTests(unittest.TestCase):
 def test_target_pom_coordinate_and_hash(self):
  for t in json.loads((E/'target-provenance.json').read_text()):
   f=next(f for f in t['files'] if f['url'].endswith('.pom'))
   b=(E/f['evidencePath']).read_bytes();self.assertEqual(hashlib.sha256(b).hexdigest(),f['sha256'])
   xml=ET.fromstring(b);ns={'m':'http://maven.apache.org/POM/4.0.0'}
   self.assertEqual(':'.join(xml.findtext('m:'+x,namespaces=ns) for x in ['groupId','artifactId','version']),t['module'])
 def test_retained_notices_keep_exact_hashes(self):
  for t in json.loads((E/'target-provenance.json').read_text()):
   for f in t['retainedNotices']:self.assertEqual(hashlib.sha256((E/f['path']).read_bytes()).hexdigest(),f['sha256'])
 def test_all_plugin_inputs_are_authenticated_and_hashed(self):
  rows=json.loads((E/'plugin-inputs.json').read_text())
  self.assertEqual(len(rows),len({r['name'] for r in rows}))
  for r in rows:
   self.assertTrue(r['sourceVerified']);self.assertEqual(hashlib.sha256((E/r['path']).read_bytes()).hexdigest(),r['sha256'])
   self.assertTrue(r['acquisitionUrl'].startswith('https://'))
   if r['source']=='git':self.assertRegex(r['gitRevision'],r'^[a-f0-9]{40}$')
 def test_target_resolution_never_claims_licence_clearance(self):
  rows=json.loads((E/'target-provenance.json').read_text());self.assertEqual(len(rows),5)
  for r in rows:self.assertEqual(r['licenseDeclared'],'NOASSERTION');self.assertFalse(r['legalClearance'])
if __name__=='__main__':unittest.main()
