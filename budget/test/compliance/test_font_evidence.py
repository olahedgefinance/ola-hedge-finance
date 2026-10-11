import unittest, importlib.util, json, copy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
SPEC=importlib.util.spec_from_file_location('fonts',ROOT/'budget/tool/compliance/verify_font_evidence.py')
f=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(f)
class FontEvidenceTests(unittest.TestCase):
    def test_all_bundled_metadata_is_reproduced(self):
        m=f.verify(ROOT);self.assertEqual(sum(len(r['files']) for r in m['records']),13)
    def test_one_conditional_declaration_and_six_blocked(self):
        m=f.verify(ROOT);self.assertEqual([r['id'] for r in m['records'] if r['licenseDeclared']!='NOASSERTION'],['font:DMSans'])
    def test_dependency_inventory_includes_runtime_and_source_inputs(self):
        m=f.verify(ROOT);self.assertEqual(len(m['dependencyFonts']),7);self.assertEqual(sum(r['distribution']=='runtime-distributed' for r in m['dependencyFonts']),4)
    def test_archive_digest_mismatch_is_rejected(self):
        r=f.verify(ROOT)['dependencyFonts'][0]
        with self.assertRaises(ValueError):f.validate_archive(b'wrong',[r],'tar')
    def test_unsafe_paths_are_rejected(self):
        for p in ['../x','/x','C:/x','a'+chr(92)+'b']:
            with self.assertRaises(ValueError):f.safe(p)
    def test_binary_metadata_does_not_supply_clearance(self):
        rows=f.verify(ROOT)['records'];r=next(r for r in rows if r['id']=='font:Avenir')
        self.assertEqual(r['classification'],'Counsel Review Required');self.assertEqual(r['licenseDeclared'],'NOASSERTION')
    def test_locked_version_or_digest_drift_fails(self):
        m=f.verify(ROOT);folder=ROOT/f.REL
        lock=(ROOT/'budget/pubspec.lock').read_text(encoding='utf8');pin=(folder/m['flutterSource']['pinPath']).read_text(encoding='utf8');observed=json.loads((folder/'font-manifest.observed.json').read_text(encoding='utf8'))
        for bad in [lock.replace('4.2768.0','4.9999.0'),lock.replace(m['_release']['archive_sha256'],'0'*64)]:
            with self.assertRaises(ValueError):f.dependency_context(m,bad,'3.19.6',pin,observed)
    def test_missing_dependency_font_or_sdk_pin_fails(self):
        original=f.verify(ROOT);folder=ROOT/f.REL;lock=(ROOT/'budget/pubspec.lock').read_text(encoding='utf8');pin=(folder/original['flutterSource']['pinPath']).read_text(encoding='utf8');observed=json.loads((folder/'font-manifest.observed.json').read_text(encoding='utf8'))
        m=copy.deepcopy(original);m['dependencyFonts'].pop(0)
        with self.assertRaises(ValueError):f.dependency_context(m,lock,'3.19.6',pin,observed)
        with self.assertRaises(ValueError):f.dependency_context(original,lock,'3.19.6','wrong',observed)
        with self.assertRaises(ValueError):f.dependency_context(original,lock,'3.19.6',pin,observed[:-1])
if __name__=='__main__':unittest.main()
