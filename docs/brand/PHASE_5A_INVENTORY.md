# Phase 5A pre-edit inventory

Inspected 2026-10-15 in the canonical repository before product edits.
Base: ba0299457905446f9739da545f82f28aa166653e (published SQL.js checkpoint).
Current original branch 166ef4a310b5a4f1acfcf3f21e5fca4022823e05 is unpublished and preserved.

| Class | Locations / findings | Phase 5A treatment |
|---|---|---|
| Safe visible branding | lib/brand/brand_identity.dart; brand/brand_manifest.json; Android label; iOS display names and permission copy; web title/social metadata; translations already mostly ÓLA HEDGE FINANCE | Keep full name; use ÓLA HEDGE short name; replace remaining current-product lowercase cashew in Norwegian/Swedish order confirmations and source CSV |
| Export presentation | widgets/exportCSV.dart, exportDB.dart, importCSV.dart, accountAndBackup.dart use cashew- prefixes | Rename user-visible filenames only; preserve content, extensions, database names and import compatibility |
| Assets | assets/icon; Android mipmaps/notification drawable; iOS AppIcon and LaunchImage sets; web icons/favicon; web social preview references a missing assets/preview.png | No cleared ÓLA production mark identified. Use plain, reproducible OLA / DEV placeholders, clearly documented as internal-only; retain asset dimensions and platform structure |
| Visual foundation | colors.dart; struct/defaultPreferences.dart; settings font picker; bundled Inter regular/bold | Reusable palette, semantic light/dark schemes, spacing/radius/elevation tokens. Inter/default Emerald for new users. Saved preferences retained |
| Safe identifiers already migrated | Android namespace/base ID com.olahedgefinance.app; development .dev and staging .staging; matching iOS app/test identifiers | Retain; no migration needed for this task. Dart package budget remains to avoid import churn |
| Services/tooling | config/infrastructure_config.dart; Firebase/bootstrap; .firebaserc.example; Android conditional Google Services; platform environment configs | Preserve. Cloud/OAuth/store/domain values require owner-owned infrastructure; do not provision or rename |
| Required provenance/history | LICENSE; legal/; compliance/; upstream repository link; James/YuYing credits; showChangelog.dart; translation import-warning-description | Preserve. Clarify upstream credits rather than implying current product ownership |
| Internal compatibility symbols | CashewAppMain; CashewProBanner; enjoying-cashew-question localization key | Preserve internal keys; they are not visible product copy |
| Historical documentation | README, docs/transformation, old reports, promotional material and evidence snapshots | Preserve historical material; do not bulk replace repository history/evidence |

No financial algorithms, schema/migrations, backup formats, cloud identifiers or compliance evidence are in implementation scope. Broad localization beyond unambiguous literal branding needs a separate language review.

## Follow-up found during independent review

Current-product order-confirmation strings also contained three misspelled/Cyrillic-lookalike Latin brand variants and fifteen localized nut-name/mistranslation tokens. Exact token substitutions were applied in bg, bn, el, fa, gu, he, hi, ko, ml, mr, ro, sr, ta, te, th, tr, uk and ur, with matching CSV cells. Surrounding prose and grammatical suffixes were preserved. This is a branding substitution, not linguistic certification of those translations. Historical import warnings and upstream credits remain.

## Owner-approved revised DEV scope

The owner directed preservation of every published checkpoint and frozen evidence
hash. The 54 historical icon outputs and five pinned text files were restored to
their evidenced bytes. Original About attribution and base identity contracts are
preserved; the earlier proposed About clarification and base compact-name edits
are not part of the final change. The 54 temporary images now use distinct DEV
paths, documented in OLA_VISUAL_FOUNDATION.md and budget/brand/DEV_ASSETS.md.
They are explicit internal overlays, not renamed files claimed as release-cleared.

The only compliance-tool change is CRLF/LF equivalence for comparing generated
text reports. It preserves all report bytes and leaves raw evidence SHA-256 checks
unchanged. A regression test rejects substantive changes, trailing spaces, missing
final newlines and missing files. No evidence inventory or classification changes.

The later Android graph evidence separately pins settings.gradle. That file was
restored too; release enforcement lives outside the frozen Gradle inputs.
