import unittest,importlib.util,copy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
SPEC=importlib.util.spec_from_file_location('fork_evidence',ROOT/'budget/tool/compliance/verify_fork_evidence.py')
mod=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(mod)
class ForkEvidenceTests(unittest.TestCase):
 def test_deleted_file_patch_headers_have_matching_paths(self):
  raw=b'diff --git a/upstream/x b/upstream/x\n--- a/upstream/x\n+++ /dev/null\n-unchanged a/upstream/text\n'
  self.assertEqual(mod.normalise_patch(raw),b'diff --git a/x b/x\n--- a/x\n+++ /dev/null\n-unchanged a/upstream/text\n')
 def test_provenance_cannot_be_substituted(self):
  folder=ROOT/mod.REL;m=mod.load(folder,'manifest.json')
  for original in m['records']:
   row=copy.deepcopy(original);proof=mod.load(folder,row['name']+('/ancestry.json' if row['source']=='git' else '/pub-version.json'))
   mod.validate_provenance(row,proof)
   row['upstreamCommit' if row['source']=='git' else 'archiveSha256']='0'*64
   with self.assertRaises(ValueError):mod.validate_provenance(row,proof)
 def test_full_offline_evidence(self):self.assertEqual(mod.verify(ROOT)['packages'],4)
 def test_added_modified_deleted_and_crlf_are_distinct(self):
  a=mod.inventory({'same':b'x','line':b'x\r\n','code':b'a','gone':b'y'})
  b=mod.inventory({'same':b'x','line':b'x\n','code':b'b','new':b'z'})
  rows=mod.delta(a,b)
  self.assertEqual([(r['path'],r['kind']) for r in rows],[('code','modified'),('gone','deleted'),('line','line-endings-only'),('new','added')])
 def test_unsafe_paths_rejected(self):
  for path in ['../escape','/absolute','C:/drive','x\\y']:
   with self.assertRaises(ValueError):mod.inventory({path:b'bad'})
 def test_missing_delta_entry_rejected(self):
  a=mod.inventory({'x':b'a'});b=mod.inventory({'x':b'b'})
  with self.assertRaises(ValueError):mod.validate_delta(a,b,[])
 def test_fabricated_delta_rejected(self):
  a=mod.inventory({'x':b'a'})
  with self.assertRaises(ValueError):mod.validate_delta(a,a,[{'path':'x','kind':'modified'}])
 def test_duplicate_source_paths_rejected(self):
  a=mod.inventory({'x':b'a'})
  with self.assertRaises(ValueError):mod.delta(a+a,a)
 def test_tampered_payload_rejected(self):
  with self.assertRaises(ValueError):mod.require_hash(b'changed','0'*64)
 def test_missing_historical_git_base_does_not_become_git_ancestry(self):
  row={'comparisonKind':'published-archive','upstreamCommit':None,'historicalGitBase':'UNAVAILABLE'}
  self.assertFalse(mod.has_git_ancestry(row))
if __name__=='__main__':unittest.main()
