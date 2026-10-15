"""Validate supplemental DEV artwork. Never amend frozen checkpoint evidence."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

MESSAGE = 'TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED'
STATUS = 'DEV ONLY / NOT RELEASE CLEARED'
PREFIXES = ('assets/icon/ola_dev_', 'android/app/src/debug/res/',
            'ios/Runner/Assets.xcassets/OlaDev', 'web/branding/dev/')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(root):
    manifest = json.loads((root / 'brand/development_assets.json').read_text(encoding='utf-8'))
    if manifest.get('status') != STATUS or manifest.get('schemaVersion') != 2:
        raise ValueError('Development evidence cannot assert release clearance')
    rows = manifest['assets']
    if len(rows) != 54 or len({r['path'] for r in rows}) != 54:
        raise ValueError('Expected exactly 54 unique development assets')
    for row in rows:
        path = row['path']
        if ('..' in Path(path).parts or ':' in path or '\\' in path
                or not path.startswith(PREFIXES)):
            raise ValueError('Unsafe or non-development asset path: ' + path)
        if row.get('status') != STATUS or not all(row.get(k) for k in ('purpose', 'provenance', 'replacement')):
            raise ValueError('Missing DEV-only status, provenance or replacement: ' + path)
        if digest(root / path) != row['sha256']:
            raise ValueError('Development asset hash mismatch: ' + path)
    print('54 development assets verified; DEV ONLY / NOT RELEASE CLEARED')


def frozen(root):
    manifest = json.loads((root / 'brand/development_assets.json').read_text(encoding='utf-8'))
    repo = root.parent
    path = repo / manifest['frozenEvidenceIndex']
    if digest(path) != manifest['frozenEvidenceIndexSha256']:
        raise ValueError('Frozen evidence index changed')
    records = json.loads(path.read_text(encoding='utf-8'))['files']
    for row in records:
        if digest(repo / row['path']) != row['sha256']:
            raise ValueError('Frozen evidence hash mismatch: ' + row['path'])
    print(f'{len(records)} frozen evidence hashes match; index unchanged')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--frozen', action='store_true')
    mode.add_argument('--release', action='store_true')
    args = parser.parse_args()
    # Fail closed even if the supplemental manifest is missing/corrupted.
    # Removing these guards requires explicit production-artwork review.
    if args.release:
        print(MESSAGE, file=sys.stderr)
        return 1
    try:
        (frozen if args.frozen else check)(args.root.resolve())
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
