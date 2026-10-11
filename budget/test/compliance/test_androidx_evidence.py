from pathlib import Path
import importlib.util, json, hashlib, unittest, io, zipfile, copy
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('androidx_replay',ROOT/'budget/tool/compliance/verify_androidx_evidence.py')
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
E=ROOT/v.EVIDENCE
class AndroidXEvidenceTests(unittest.TestCase):
 def test_exact_publisher_archives_graph_and_scope_replay(self):
  self.assertEqual(v.verify(ROOT),{'reviewed':59,'resolved':50,'remaining':9})
 def changed_manifest(self, mutate):
  manifest=json.loads((E/'manifest.json').read_text(encoding='utf-8'))
  replacements={}
  mutate(manifest, replacements)
  original_text=Path.read_text; original_bytes=Path.read_bytes
  def read_text(path,*args,**kwargs):
   if path==E/'manifest.json':return json.dumps(manifest)
   return original_text(path,*args,**kwargs)
  def read_bytes(path,*args,**kwargs):
   return replacements[path] if path in replacements else original_bytes(path,*args,**kwargs)
  with patch.object(Path,'read_text',read_text),patch.object(Path,'read_bytes',read_bytes):
   return v.verify(ROOT)
 def test_missing_source_fails_even_with_rehashed_matching_audit(self):
  def mutate(manifest, replacements):
   row=manifest['records'][0]
   source=next(f for f in row['files'] if f['role']=='source')
   row['files'].remove(source)
   audit=json.loads((E/row['audit']['path']).read_text(encoding='utf-8'))
   del audit['archives'][source['filename']]
   data=json.dumps(audit).encode();h=v.digest(data);p='blobs/'+h+'.bin'
   replacements[E/p]=data;row['audit']={'path':p,'sha256':h,'bytes':len(data)}
  with self.assertRaisesRegex(ValueError,'source/POM'):self.changed_manifest(mutate)
 def test_duplicate_publisher_file_fails(self):
  def mutate(manifest,replacements):
   row=manifest['records'][0];row['files'].append(copy.deepcopy(row['files'][0]))
  with self.assertRaisesRegex(ValueError,'[Dd]uplicate'):self.changed_manifest(mutate)
 def test_role_cannot_substitute_for_exact_release_filename(self):
  def mutate(manifest,replacements):
   row=manifest['records'][0];next(f for f in row['files'] if f['role']=='source')['role']='extra'
  with self.assertRaisesRegex(ValueError,'source/POM|role|Role'):self.changed_manifest(mutate)
 def archive(self,files):
  b=io.BytesIO()
  with zipfile.ZipFile(b,'w') as z:
   for path,content in files:z.writestr(path,content)
  return b.getvalue()
 def test_top_level_apache_text_does_not_clear_embedded_implementation(self):
  audit=v.inspect_archive(self.archive([('LICENSE','Apache License Version 2.0'),('androidx/example/protobuf/Message.class',b'bytes')]))
  self.assertTrue(audit['risks']);self.assertEqual(audit['noticeNamedEntries'],['LICENSE'])
 def test_nested_notice_and_dex_are_not_omitted(self):
  nested=self.archive([('META-INF/NOTICE','copyright holder'),('classes.dex',b'dex')])
  audit=v.inspect_archive(self.archive([('inspector.jar',nested)]))
  self.assertIn('inspector.jar!META-INF/NOTICE',audit['noticeNamedEntries'])
  self.assertTrue(any(r['path']=='inspector.jar!classes.dex' for r in audit['risks']))
 def test_resources_require_separate_scope_review(self):
  self.assertTrue(v.inspect_archive(self.archive([('res/icon.png',b'image')]))['risks'])
 def test_substantive_missing_header_is_not_an_empty_file(self):
  self.assertTrue(v.inspect_archive(self.archive([('Source.kt',b'class Foo {}')]),True)['risks'])
  self.assertFalse(v.inspect_archive(self.archive([('Empty.kt',b''),('Parcel.aidl',b'package test; parcelable Parcel;')]),True)['risks'])
 def test_unsafe_or_duplicate_archive_entries_fail(self):
  for files in [[('../file',b'')],[('same',b'a'),('same',b'b')]]:
   with self.assertRaises(ValueError):v.inspect_archive(self.archive(files))
 def test_notice_discovery_does_not_assert_absence_of_obligations(self):
  a=v.inspect_archive(self.archive([('Thing.java',b'// Licensed under the Apache License, Version 2.0\nclass Thing {}')]),True)
  self.assertFalse(a['risks']);self.assertEqual(a['noticeNamedEntries'],[])
if __name__=='__main__':unittest.main()
