# Open-source and generated-material review policy

This engineering policy governs dependency and third-party material review for ÓLA HEDGE FINANCE. It organizes evidence and release gates; it is not a legal opinion. Unusual terms, ambiguity, commercial distribution, copyleft interaction, and store-specific questions require qualified counsel.

## Licence classes

| Class | Examples | Engineering treatment |
|---|---|---|
| Normally acceptable / low-friction | MIT, BSD-family, Apache-2.0, ISC | Record exact version, source, licence evidence, notices, distribution status, and any Apache NOTICE/patent obligations. Normal review may approve. |
| Review required | LGPL, MPL, EPL, custom or uncommon terms | Do not approve from the identifier alone. Review linking/modification/source/notice obligations and distribution model with a qualified reviewer. |
| High-impact / reciprocal | GPL, AGPL, other strong copyleft | Architecture and release process must satisfy reciprocal source and notice obligations. Counsel review is required before commercial distribution. |
| Block until resolved | No licence, unknown/ambiguous/conflicting evidence, proprietary material without documented permission | Do not ship. Obtain reliable rights evidence, replace/remove the material, or obtain permission and legal approval. `NOASSERTION` always stays in this class. |

Compatibility depends on the complete dependency graph and actual use, not just a package label. A classification is never blanket approval for a future version.

## New dependency review

Every new direct production dependency must add a completed copy of `compliance/dependency-review.template.md` to the change or provide the same fields in the pull request. The reviewer must confirm:

- name and exact version/revision;
- purpose and why an existing component is insufficient;
- authoritative package/source repository;
- licence identifier and evidence location;
- direct/transitive and distributed/not-distributed status;
- whether it is modified or vendored;
- privacy, security, network, telemetry, and platform implications;
- required notices/source obligations;
- review status and reviewer.

The lockfile and generated inventory/SBOM must be updated in the same change. Development-only tooling may use the same concise record when material to released artefacts; routine non-distributed tools need only enough evidence to keep the SBOM accurate.

## Generated and AI-assisted material

Significant AI-generated or externally generated code, documentation, images, icons, audio, datasets, or other assets must be reviewed for provenance, third-party copying, licence headers/terms, compatibility, attribution, and modification history. Generated material is not automatically proprietary, original, unencumbered, or safe to distribute. Preserve prompts/source inputs and reviewer evidence when they are material to a rights decision, without storing secrets or personal data.

## Release and user-facing requirements

No public binary may ship while a material component is blocked or its required notices/source are absent. Each release must use the repository compliance gate and receive the approvals recorded in its release manifest.

A later product/rebrand phase must implement an accessible Open Source / Legal screen containing the GPL notice, third-party licences/notices, Corresponding Source URL, copyright notices, and approved product/company legal information. Do not implement or claim final legal text until product ownership details and counsel-reviewed wording are available.

