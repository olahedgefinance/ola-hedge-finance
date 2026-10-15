"""Contract/tamper tests for explicitly non-release development artwork."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / 'tool/brand/check_development_assets.py'
MESSAGE = 'TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED'


class DevelopmentAssetsTest(unittest.TestCase):
    def run_guard(self, *args):
        self.assertTrue(GUARD.exists(), 'Explicit development/release guard is required')
        return subprocess.run([sys.executable, str(GUARD), *args],
                              capture_output=True, text=True, encoding='utf-8')

    def test_internal_assets_are_integral_and_separate(self):
        result = self.run_guard('--check')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        manifest = json.loads((ROOT / 'brand/development_assets.json').read_text(encoding='utf-8'))
        self.assertEqual(len(manifest['assets']), 54)
        self.assertEqual(len({x['path'] for x in manifest['assets']}), 54)
        frozen = json.loads((ROOT.parent / 'compliance/evidence/reconstruction-2026-10-09/evidence-index.json').read_text())
        pins = {r['path']: r['sha256'] for r in frozen['files']}
        for row in manifest['assets']:
            self.assertNotIn('budget/' + row['path'], pins)
            old = ROOT.parent / row['historicalPath']
            self.assertEqual(hashlib.sha256(old.read_bytes()).hexdigest(), pins[row['historicalPath']])

    def test_release_is_explicitly_blocked(self):
        result = self.run_guard('--release')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(MESSAGE, result.stdout + result.stderr)

    def test_tampering_missing_and_false_clearance_fail_closed(self):
        self.assertTrue(GUARD.exists(), 'Explicit development/release guard is required')
        manifest = json.loads((ROOT / 'brand/development_assets.json').read_text(encoding='utf-8'))
        for mutation in ('bytes', 'missing', 'status', 'traversal'):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                for row in manifest['assets']:
                    dest = base / row['path']
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / row['path'], dest)
                data = json.loads(json.dumps(manifest))
                row = data['assets'][0]
                if mutation == 'bytes':
                    (base / row['path']).write_bytes(b'changed')
                elif mutation == 'missing':
                    (base / row['path']).unlink()
                elif mutation == 'status':
                    row['status'] = 'RELEASE CLEARED'
                else:
                    row['path'] = '../escape.png'
                (base / 'brand').mkdir()
                (base / 'brand/development_assets.json').write_text(json.dumps(data), encoding='utf-8')
                result = self.run_guard('--check', '--root', str(base))
                self.assertNotEqual(result.returncode, 0)
                release = self.run_guard('--release', '--root', str(base))
                self.assertNotEqual(release.returncode, 0)
                self.assertIn(MESSAGE, release.stdout + release.stderr)


if __name__ == '__main__':
    unittest.main()
