# Hosted Pub composite licence evidence

Ten exact release archives were reacquired from Pub and matched both registry SHA-256 and the existing lock/inventory. Five source declarations are verified with conditions; five remain NOASSERTION. Full supplied notices are retained, including broader external notices. No OR election is inferred. No licenceConcluded field is cleared.

`manifest.json` binds exact versions, archive hashes, retained payloads, reviewed grant text ranges and source scope. `archive-inventory.json` records every regular file; `source-markers.json` retains a replayable attribution/licence marker index. Independent reviews explain the decisions and limitations. Retained source files are verbatim archive evidence, not changes to dependencies.

Git tag/commit equivalence is NOT ASSERTED: moving repository URLs in pubspecs are metadata, while the authenticated published tar archive is the exact source identity. Native dependencies are explicitly separate. For example, resolving a charset Pub wrapper does not resolve its CocoaPods/Maven engine.

Archives are preserved externally in the task preservation folder and can be reacquired using the manifest URLs/digests. The standalone replay script verifies complete trees and retained payloads without executing package code. Evidence-only technical verification does not mean legal clearance, Phase 2A completion or release readiness. Do Not Ship remains; historical 7f3209eebb270aaef11d875c0d214467619a0627 remains NOT RECOVERED.

## Validation layers

The Python replay command verifies archive identity, complete source-tree hashes and retained payload/marker equality. It is an archive-integrity replay, not an independent semantic declaration validator. Its success alone must not advance a declaration. The Dart generator's `verifyPubCompositeEvidence` check is mandatory: it validates reviewed source scope, exact grant-text normalisation, AND semantics, unresolved decisions and unchanged native fallback before producing output. The task verification gate runs both layers plus negative regressions.

Three complete inline Dart SDK BSD witnesses with the distinct 2012 attribution are retained for universal_html (node.dart, css_selectors.dart, css_class_set.dart). This strengthens notice preservation without resolving that package's separate MIT scope question.
