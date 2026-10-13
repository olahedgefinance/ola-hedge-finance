"""Mutation checks against retained exact publisher bytes (no mocks/network)."""
from pathlib import Path
import copy
import importlib.util
import json
import unittest
import tempfile
import shutil
import hashlib

ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('kotlin_evidence',ROOT/'budget/tool/compliance/verify_kotlin_evidence.py')
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)


class KotlinEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.m=json.loads((ROOT/v.EVIDENCE/'manifest.json').read_text(encoding='utf-8'))

    def row(self,name):
        return next(r for r in self.m['records'] if r['id']=='maven:'+name)

    def rejects(self):
        with self.assertRaises((ValueError,KeyError)):
            v.verify(ROOT,manifest=self.m)

    def test_exact_review_preserves_unresolved_debug_payload(self):
        result=v.verify(ROOT,manifest=self.m)
        self.assertEqual((result['reviewed'],result['resolved'],result['remaining']),(9,8,1))

    def test_missing_runtime_source_cannot_use_bom_rules(self):
        r=self.row('org.jetbrains.kotlin:kotlin-stdlib')
        r['files']=[f for f in r['files'] if f['role']!='source']
        self.rejects()

    def test_source_url_release_mismatch(self):
        r=self.row('org.jetbrains.kotlin:kotlin-stdlib-common')
        next(f for f in r['files'] if f['role']=='source')['url']='https://example.org/source.jar'
        self.rejects()

    def test_boost_and_scope_cannot_be_changed_to_or(self):
        self.row('org.jetbrains.kotlin:kotlin-stdlib')['licenseDeclared']='Apache-2.0 OR BSL-1.0'
        self.rejects()

    def test_debug_payload_not_cleared_by_top_level_pom(self):
        self.row('org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm')['licenseDeclared']='Apache-2.0'
        self.rejects()

    def test_notice_missing_fails(self):
        u=next(u for u in self.m['upstreams'] if u['tag']=='1.7.3')
        u['files']=[f for f in u['files'] if f['sourcePath']!='license/NOTICE.txt']
        self.rejects()

    def test_bom_upstream_version_cannot_follow_stdlib_version(self):
        self.row('org.jetbrains.kotlin:kotlin-bom')['upstreamKey']='v1.9.0'
        self.rejects()

    def test_graph_binding_cannot_be_relabelled(self):
        self.m['graphSha256']='0'*64
        self.rejects()

    def test_duplicate_cohort_row_rejected(self):
        self.m['records'].append(copy.deepcopy(self.m['records'][0]))
        self.rejects()

    def test_missing_published_module_metadata_rejected(self):
        r=self.row('org.jetbrains.kotlinx:kotlinx-coroutines-android')
        r['files']=[f for f in r['files'] if f['role']!='module']
        self.rejects()

    def test_rehashed_wrong_module_version_rejected(self):
        self.mutate_module('org.jetbrains.kotlinx:kotlinx-coroutines-play-services',lambda m:m['component'].update(version='0.0.0'))

    def test_rehashed_artifact_checksum_rejected(self):
        def change(m):
            f=next(f for var in m['variants'] for f in var.get('files',[]) if f['name'].endswith('.jar'))
            f['sha256']='0'*64
        self.mutate_module('org.jetbrains.kotlinx:kotlinx-coroutines-android',change)

    def test_rehashed_parent_url_rejected(self):
        self.mutate_module('org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm',lambda m:m['component'].update(url='../../wrong/1.7.3/wrong-1.7.3.module'))

    def mutate_module(self,name,change):
        with tempfile.TemporaryDirectory(prefix='ola-kotlin-test-') as tmp:
            root=Path(tmp)
            shutil.copytree(ROOT/v.EVIDENCE,root/v.EVIDENCE)
            graph=root/self.m['graphPath'];graph.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(ROOT/self.m['graphPath'],graph)
            f=next(f for f in self.row(name)['files'] if f['role']=='module')
            data=json.loads((ROOT/v.EVIDENCE/f['path']).read_bytes());change(data)
            raw=json.dumps(data).encode();h=hashlib.sha256(raw).hexdigest()
            f.update(path='blobs/'+h+'.bin',sha256=h,bytes=len(raw))
            (root/v.EVIDENCE/f['path']).write_bytes(raw)
            with self.assertRaises(ValueError):v.verify(root,manifest=self.m)

    def test_unrelated_namespace_rejected(self):
        r=self.row('org.jetbrains.kotlin:kotlin-stdlib')
        r['coordinate']='org.jetbrains:annotations:1.9.0';r['id']='maven:org.jetbrains:annotations'
        self.rejects()


if __name__=='__main__':
    unittest.main()
