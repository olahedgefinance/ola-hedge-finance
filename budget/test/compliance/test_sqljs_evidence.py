import unittest,sys,importlib.util
from pathlib import Path
TOOL=Path(__file__).resolve().parents[2]/"tool/compliance/verify_sqljs_evidence.py"
spec=importlib.util.spec_from_file_location("sqljs_evidence",TOOL);v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
class ComparisonTests(unittest.TestCase):
 def test_exact_published_bytes_and_documented_crlf_transform(self):
  result=v.compare_artifacts({"sql-wasm.wasm":b"wasm","sql-wasm.js":b"a\nb","worker.sql-wasm.js":b"w\nx"},{"sql-wasm.wasm":b"wasm","sql-wasm.js":b"a\r\nb","worker.sql-wasm.js":b"w\r\nx"})
  self.assertEqual(result["classification"],"Exact reproducible match")
  self.assertEqual(result["transforms"],{"sql-wasm.wasm":"identity","sql-wasm.js":"LF-to-CRLF","worker.sql-wasm.js":"LF-to-CRLF"})
 def test_wasm_bytes_are_never_line_ending_normalised(self):
  result=v.compare_artifacts({"sql-wasm.wasm":b"a\nb","sql-wasm.js":b"a","worker.sql-wasm.js":b"b"},{"sql-wasm.wasm":b"a\r\nb","sql-wasm.js":b"a","worker.sql-wasm.js":b"b"})
  self.assertEqual(result["classification"],"Build succeeds but provenance mismatch remains")
 def test_js_semantic_equivalence_is_not_inferred(self):
  result=v.compare_artifacts({"sql-wasm.wasm":b"w","sql-wasm.js":b"a;","worker.sql-wasm.js":b"b"},{"sql-wasm.wasm":b"w","sql-wasm.js":b"a ;","worker.sql-wasm.js":b"b"})
  self.assertEqual(result["classification"],"Build succeeds but provenance mismatch remains")
 def test_missing_output_is_a_failed_build(self):
  self.assertEqual(v.compare_artifacts({}, {})["classification"],"Build cannot be reproduced")


class MetadataTests(unittest.TestCase):
 def valid(self):
  return {"version":"1.6.2","sourceCommit":"997d56fb954b63e76cf8d549c4660c972381768e","expectedEmscripten":"2.0.29","observedEmscripten":"2.0.29","buildExit":0,"legalClearance":False,"releaseClearance":False,"gapClosed":False,"publishedCompilerProven":False,"conditions":["Technical evidence only; not legal/release clearance or Phase 2A completion.","Contribution licence/attribution scope, compiler runtime notices and final release source/notices delivery remain unverified.","Do Not Ship remains. Native production verification remains incomplete."]}
 def test_supported_metadata(self):
  self.assertIsNone(v.validate_metadata(self.valid()))
 def test_different_release_cannot_reuse_proof(self):
  m=self.valid();m["version"]="1.6.3"
  with self.assertRaises(ValueError):v.validate_metadata(m)
 def test_different_source_cannot_reuse_proof(self):
  m=self.valid();m["sourceCommit"]="0"*40
  with self.assertRaises(ValueError):v.validate_metadata(m)
 def test_comment_compiler_does_not_override_release_pin(self):
  m=self.valid();m["expectedEmscripten"]="2.0.15"
  with self.assertRaises(ValueError):v.validate_metadata(m)
 def test_observed_compiler_must_match_recipe(self):
  m=self.valid();m["observedEmscripten"]="2.0.15"
  with self.assertRaises(ValueError):v.validate_metadata(m)
 def test_replay_failure_not_evidence_of_success(self):
  m=self.valid();m["buildExit"]=2
  with self.assertRaises(ValueError):v.validate_metadata(m)
 def test_no_legal_release_or_gap_clearance_from_bytes(self):
  for k in ("legalClearance","releaseClearance","gapClosed","publishedCompilerProven"):
   m=self.valid();m[k]=True
   with self.subTest(k=k),self.assertRaises(ValueError):v.validate_metadata(m)
 def test_conditions_cannot_be_dropped(self):
  m=self.valid();m["conditions"]=[]
  with self.assertRaises(ValueError):v.validate_metadata(m)


import os,json,copy
ROOT=Path(os.environ.get("SQLJS_TEST_ROOT",str(Path(__file__).resolve().parents[3])))
class ProofTests(unittest.TestCase):
 def setUp(self):
  self.m=json.loads((ROOT/"compliance/evidence/reconstruction-2026-10-09/sqljs-build-2026-10-13/manifest.json").read_text())
 def test_full_archives_and_shipped_files_verify(self):
  r=v.verify(ROOT,self.m)
  self.assertEqual(r["version"],"1.6.2")
  self.assertFalse(r["gapClosed"])
 def test_wrong_archive_digest_rejected(self):
  self.m["inputs"]["source.zip"]["sha256"]="0"*64
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_source_url_must_name_exact_upstream_commit(self):
  self.m["inputs"]["source.zip"]["url"]="https://example.com/source.zip"
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_unsafe_evidence_path_rejected(self):
  self.m["inputs"]["source.zip"]["path"]="../source.zip"
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_missing_build_source_hash_rejected(self):
  del self.m["buildInputHashes"]["Makefile"]
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_shipped_hash_mismatch_rejected(self):
  self.m["records"][0]["sha256"]="0"*64
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_comparison_is_recomputed(self):
  self.m["comparison"]={"classification":"made-up","transforms":{}}
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_repeatability_claim_is_recomputed(self):
  self.m["repeatBuild"]["sameAsFirst"]=False
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_sdk_archive_identity_is_required(self):
  self.m["toolArchives"]=[]
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
 def test_sdk_archive_hash_cannot_be_invalid(self):
  self.m["toolArchives"][0]["sha256"]="not-a-hash"
  with self.assertRaises(ValueError):v.verify(ROOT,self.m)
if __name__=="__main__":unittest.main()
