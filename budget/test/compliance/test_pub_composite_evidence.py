import unittest,importlib.util,copy,io,tarfile,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
SPEC=importlib.util.spec_from_file_location('pub_composite',ROOT/'budget/tool/compliance/verify_pub_composite_evidence.py')
mod=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(mod)
FOLDER=ROOT/mod.REL
ROWS=json.loads((FOLDER/'manifest.json').read_text())['records']
def archive(entries):
    out=io.BytesIO()
    with tarfile.open(fileobj=out,mode='w:gz') as tf:
        for path,content in entries:
            item=tarfile.TarInfo(path);item.size=len(content);tf.addfile(item,io.BytesIO(content))
    return out.getvalue()
class PubCompositeTests(unittest.TestCase):
    def test_all_ten_exact_evidence_records(self):self.assertEqual(mod.verify(ROOT)['packages'],10)
    def test_exact_archive_tree_is_reproducible(self):
        raw=archive([('LICENSE',b'notice'),('lib/a.dart',b'// source')])
        files=mod.archive_files(raw,mod.digest(raw))
        self.assertEqual(mod.inventory(files),[{'path':'LICENSE','bytes':6,'sha256':mod.digest(b'notice')},{'path':'lib/a.dart','bytes':9,'sha256':mod.digest(b'// source')}])
    def test_archive_digest_tamper_rejected(self):
        with self.assertRaises(ValueError):mod.archive_files(b'bad','0'*64)
    def test_unsafe_paths_rejected(self):
        for path in ['../x','/root','C:/drive','x\\y']:
            with self.assertRaises(ValueError):mod.safe(path)
    def test_duplicate_archive_file_rejected(self):
        raw=archive([('x',b'a'),('x',b'b')])
        with self.assertRaises(ValueError):mod.archive_files(raw,mod.digest(raw))
    def test_notice_markers_keep_source_lines_and_copyright(self):
        data=b'// Copyright Example\ncode\n// Licensed under BSD\n'
        self.assertEqual([r['line'] for r in mod.source_markers({'a.dart':data})[0]['markers']],[1,3])
    def test_and_never_becomes_or(self):
        row=copy.deepcopy(next(r for r in ROWS if r['name']=='vector_math'));row['declaration']='BSD-3-Clause OR Zlib'
        with self.assertRaises(ValueError):mod.validate_declaration(row)
    def test_unresolved_cannot_be_promoted(self):
        row=copy.deepcopy(next(r for r in ROWS if r['name']=='url_launcher_web'));row['declaration']='BSD-3-Clause'
        with self.assertRaises(ValueError):mod.validate_declaration(row)
    def test_release_identity_or_clearance_tamper_rejected(self):
        original=ROWS[0];release=json.loads((FOLDER/original['releaseMetadataPath']).read_text())
        for key,value in [('archiveSha256','0'*64),('version','9.9.9'),('gitTag','invented'),('legalClearance',True)]:
            row=copy.deepcopy(original);row[key]=value
            with self.assertRaises(ValueError):mod.validate_identity(row,release)
    def test_all_five_supported_expressions_remain_conditional(self):
        verified=[r for r in ROWS if r['declaration']!='NOASSERTION']
        self.assertEqual(len(verified),5)
        for row in verified:
            mod.validate_declaration(row)
            self.assertEqual(row['classification'],'Verified with conditions')
            self.assertFalse(row['legalClearance']);self.assertFalse(row['releaseClearance'])
if __name__=='__main__':unittest.main()
