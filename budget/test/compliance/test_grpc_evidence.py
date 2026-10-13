from pathlib import Path
import copy,importlib.util,json,unittest,io,zipfile
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('grpc',ROOT/'budget/tool/compliance/verify_grpc_evidence.py');grpc=importlib.util.module_from_spec(spec);spec.loader.exec_module(grpc)
class GrpcEvidenceTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.original=json.loads((ROOT/grpc.EVIDENCE/'manifest.json').read_text())
 def setUp(self):self.m=copy.deepcopy(self.original)
 def row(self,name):return next(r for r in self.m['records'] if r['module']==name)
 def verify(self):return grpc.verify(ROOT,manifest=self.m)
 def test_exact_scope(self):
  r=self.verify();self.assertEqual((r['reviewed'],r['resolved'],r['remaining']),(7,4,3))
 def test_no_apache_blanket_clearance(self):
  r=self.row('okhttp');r.update(licenseDeclared='Apache-2.0',classification='Verified with conditions')
  with self.assertRaises(ValueError):self.verify()
 def test_missing_source(self):
  self.row('api')['files']=[f for f in self.row('api')['files'] if f['role']!='source']
  with self.assertRaises(ValueError):self.verify()
 def test_wrong_publisher(self):
  self.row('api')['files'][1]['url']='https://example.org/source.jar'
  with self.assertRaises(ValueError):self.verify()
 def test_wrong_tag(self):
  self.m['upstream']['tag']='v1.57.1'
  with self.assertRaises(ValueError):self.verify()
 def test_wrong_commit(self):
  self.m['upstream']['commit']='0'*40
  with self.assertRaises(ValueError):self.verify()
 def test_changed_payload(self):
  self.row('core')['files'][0]['bytes']=1
  with self.assertRaises(ValueError):self.verify()
 def test_stale_graph(self):
  self.m['graphSha256']='0'*64
  with self.assertRaises(ValueError):self.verify()
 def test_wrong_plugin_relationship(self):
  self.row('api')['flutterPluginAncestors']=[]
  with self.assertRaises(ValueError):self.verify()
 def test_cannot_claim_release_clearance(self):
  self.m['releaseClearance']=True
  with self.assertRaises(ValueError):self.verify()
 def test_missing_module(self):
  self.m['records'].pop()
  with self.assertRaises(ValueError):self.verify()
 def test_wrong_version(self):
  self.row('android')['version']='1.58.0'
  with self.assertRaises(ValueError):self.verify()
 def test_zip_path_traversal(self):
  b=io.BytesIO()
  with zipfile.ZipFile(b,'w') as z:z.writestr('../bad','test')
  with self.assertRaises(ValueError):grpc.unzip(b.getvalue())
 def test_unknown_binary_payload_remains_a_risk(self):
  def archive(files):
   b=io.BytesIO()
   with zipfile.ZipFile(b,'w') as z:
    for k,v in files.items():z.writestr(k,v)
   return b.getvalue()
  result=grpc.audit_sources(archive({'META-INF/MANIFEST.MF':b''}),archive({'io/grpc/foreign.class':b'bad','native.so':b'bad'}),{},'core')
  self.assertEqual(len(result['risks']),2)
 def test_copied_guava_scope_remains_unresolved(self):
  result=self.verify()
  for module in ['grpc-core','grpc-protobuf-lite']:
   self.assertEqual(next(r['licenseDeclared'] for r in result['records'] if r['coordinate']=='io.grpc:'+module+':1.57.2'),'NOASSERTION')
 def test_risk_summary_cannot_hide_unresolved_scope(self):
  self.row('okhttp')['risksSummary']=[]
  with self.assertRaises(ValueError):self.verify()
 def test_mandatory_conditions_cannot_be_erased(self):
  self.row('okhttp')['conditions']=['','','']
  with self.assertRaises(ValueError):self.verify()
if __name__=='__main__':unittest.main()
