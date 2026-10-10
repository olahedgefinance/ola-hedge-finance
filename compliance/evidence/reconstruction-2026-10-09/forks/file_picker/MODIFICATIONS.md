# file_picker 6.0.1: source comparison and modification record

Recorded 2026-10-09; comparison target is immutable source identity in manifest.json.
Android picker uses ACTION_OPEN_DOCUMENT and an image chooser, propagates dialogTitle through the plugin/channel, preserves activity result handling; package version changes from 6.0.0 to 6.0.1. Some Java formatting also changes.

Baseline kind: git-ancestor. Upstream Git commit: 411bb01ea3b29ee625e717de9c7af2f107d7e6eb; archive digest: not applicable.
Target commit: ccbb9a384491cc0759f94618bb3859411e228091; canonical path: locked Git dependency.
This records inherited modifications; it does not claim these changes were authored by ÓLA or made on this record date. Git authors/dates are retained in commits.txt or vendoring-history.txt.
For published archives, this is an authenticated versioned release comparison, not proof of a historical Git fork point. The historical upstream Git base is unavailable and is not inferred.

Raw change counts: {"added": 0, "modified": 4, "line-endings-only": 0, "deleted": 0}. Raw CRLF differences are retained in the complete binary-capable patch; separate line-ending-only labels avoid describing them as code changes. All omitted example files, including binaries, are listed in delta.json; no omitted files are silently excluded.

Licence and headers: MIT root licence is unchanged after CRLF normalization. Raw bytes/digests are retained on both sides. Licence/notice-path differences: []. Copyright/SPDX/licensed-under statements in retained source files are recorded in header-review.json and preserved. Files absent on the target side are disclosed in the full delta, not claimed retained.

Technical obligations to carry into release review:
- Preserve original copyright and MIT permission text in copies/substantial portions, including modified distributions.
- Retain this source/delta record and avoid reattributing upstream or inherited author work to ÓLA.
- MIT text permits modification; this is technical evidence of the retained grant, not final legal clearance. This record does not assert MIT alone requires publication of all modified source.
- Include exact source revisions/archives and complete patches in release-specific source mapping as applicable to the overall application; assess combined distribution/GPL/store obligations separately with qualified counsel.
- This is a central modification record, not evidence that final binaries, bundled notices or Corresponding Source delivery have been verified.

Files changed (complete classifications):
- modified: `android/src/main/java/com/mr/flutter/plugin/filepicker/FilePickerDelegate.java`
- modified: `android/src/main/java/com/mr/flutter/plugin/filepicker/FilePickerPlugin.java`
- modified: `lib/src/file_picker_io.dart`
- modified: `pubspec.yaml`
