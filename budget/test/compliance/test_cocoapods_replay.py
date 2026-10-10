"""Offline replay regression tests; mutations occur only in temporary fixtures."""
import contextlib,importlib.util,io,json,shutil,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
REL=Path('compliance/evidence/reconstruction-2026-10-09/native/cocoapods-source-2026-10-09')
spec=importlib.util.spec_from_file_location('pod_replay',ROOT/REL/'replay.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)

class ReplayTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='ola-pod-replay-')
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve()
        self.folder=self.root/REL
        shutil.copytree(ROOT/REL,self.folder)
        native=self.folder.parent
        shutil.copytree(ROOT/REL.parent/'packages',native/'packages')
        shutil.copyfile(ROOT/REL.parent/'native-wrapper-cache-inventory.json',native/'native-wrapper-cache-inventory.json')
        (native.parent/'pub').mkdir()
        shutil.copyfile(ROOT/REL.parent.parent/'pub/manifest.json',native.parent/'pub/manifest.json')
        (self.root/'budget/ios').mkdir(parents=True)
        shutil.copyfile(ROOT/'budget/ios/Podfile.lock',self.root/'budget/ios/Podfile.lock')
    def run_replay(self):
        with contextlib.redirect_stdout(io.StringIO()):module.replay(self.folder)
    def test_real_crlf_lock_and_evidence_replay(self):self.run_replay()
    def test_tampered_spec_rejected(self):
        (self.folder/'pods/AppAuth/spec.json').write_text('{}')
        with self.assertRaises(AssertionError):self.run_replay()
    def test_tampered_source_licence_rejected(self):
        (self.folder/'pods/AppAuth/LICENSE.source').write_text('wrong')
        with self.assertRaises(AssertionError):self.run_replay()
    def test_stale_lock_rejected(self):
        (self.root/'budget/ios/Podfile.lock').write_text('wrong')
        with self.assertRaises(AssertionError):self.run_replay()
    def test_missing_registry_record_rejected(self):
        p=self.folder/'manifest.json';m=json.loads(p.read_text());m['records'].pop();p.write_text(json.dumps(m))
        with self.assertRaises(AssertionError):self.run_replay()
    def test_path_escape_rejected(self):
        p=self.folder/'manifest.json';m=json.loads(p.read_text());m['records'][0]['specFile']='../escape';p.write_text(json.dumps(m))
        with self.assertRaises(AssertionError):self.run_replay()
    def test_substituted_licence_url_rejected(self):
        p=self.folder/'manifest.json';m=json.loads(p.read_text());m['records'][0]['licenceUrl']='https://example.invalid/LICENSE';p.write_text(json.dumps(m))
        with self.assertRaises(AssertionError):self.run_replay()
    def test_altered_api_proof_rejected(self):
        p=self.folder/'pods/SwiftyGif/licence-contents-response.json';p.write_text('{}')
        with self.assertRaises(AssertionError):self.run_replay()
    def test_google_utilities_does_not_depend_on_grpc(self):
        m=json.loads((self.folder/'unresolved-start-inventory.json').read_text())
        self.assertEqual(m['lockedRootDependencyEdges']['GoogleUtilities'],['PromisesObjC'])
        self.assertIn('gRPC-Core',m['lockedRootDependencyEdges']['gRPC-C++'])
    def test_fabricated_dependency_edge_rejected(self):
        p=self.folder/'unresolved-start-inventory.json';m=json.loads(p.read_text());m['lockedRootDependencyEdges']['AppAuth']=['fake'];p.write_text(json.dumps(m))
        with self.assertRaises(AssertionError):self.run_replay()

if __name__=='__main__':unittest.main()
