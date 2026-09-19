# License Review

> This is a technical compliance review, not legal advice. A lawyer experienced in open-source licensing and mobile-store distribution should review the intended commercial distribution model before product investment or release.

## Repository license

The root `LICENSE` contains GNU General Public License version 3 and applies it to “Cashew: an expense budget tracking application.” The project-specific notice is copyright © 2023 James Kokoska and grants redistribution/modification under GPL version 3 or, at the recipient's option, any later version. The effective classification is therefore **GPL-3.0-or-later**.

The authoritative [GNU GPLv3 text](https://www.gnu.org/licenses/gpl.en.html) should be used for compliance decisions; the repository copy must remain intact.

## Core obligations when distributing a modified app

Subject to legal confirmation, GPLv3 generally requires the distributor to:

- preserve appropriate copyright, license, and no-warranty notices;
- mark modified files or the work with prominent notices that changes were made and the relevant date;
- license the covered work, including a distributed modified whole, under GPLv3-compatible terms;
- provide recipients with the GPL license and access to the complete Corresponding Source for distributed object code, including the scripts needed to control compilation and installation;
- avoid imposing additional restrictions that prevent recipients from exercising GPL rights;
- comply with the applicable source-delivery method and offer duration in GPL section 6.

These requirements derive from the [official GPLv3 license](https://www.gnu.org/licenses/gpl.en.html), especially sections 4–7. The [GNU GPL quick guide](https://www.gnu.org/licenses/quick-guide-gplv3.en.html) provides a useful non-substitute summary.

## Commercial use

GPL does not prohibit selling software or charging for distribution or services. However, recipients must receive the GPL freedoms and the required source access. The [GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html.en) explicitly addresses selling GPL software and source-code obligations. A separately branded commercial binary built from Cashew is not automatically proprietary merely because its branding, price, or publisher changes.

## Source-distribution implications

The release process should be designed to publish the exact corresponding source for each released binary, including:

- the modified Cashew-derived source;
- local bundled package modifications;
- build and dependency metadata;
- interface definitions and scripts necessary to build/install the covered work;
- a clear version/tag mapping from store release to source archive;
- the license and attribution notices.

Secrets, signing keys, server credentials, and independent service data are not source code and must not be published. Counsel should determine which build/configuration materials are required as Corresponding Source without exposing credentials.

## Android, iOS, and web distribution

| Channel | Attention required |
|---|---|
| Android/direct APK | Include license/notice access and a durable Corresponding Source method matching the exact APK/AAB release |
| Google Play | Review current developer terms, signing, DRM, in-app purchase terms, and any restrictions for compatibility with GPL rights |
| Apple App Store | Obtain specific legal review of current store terms, DRM/signing, and GPLv3 anti-circumvention/additional-restriction provisions before committing to this channel |
| Web/PWA | Make license/source information readily accessible and map deployed/minified JavaScript to corresponding source; GNU provides [JavaScript license-label guidance](https://www.gnu.org/licenses/javascript-labels.en.html) |

Do not rely on historical statements that a store always allows or always forbids GPL software. Store agreements change, and the signing/DRM facts for the actual release matter.

## Notices that must not be removed casually

- The root GPL license and Cashew copyright notice.
- Copyright/license headers in source files, if present.
- Third-party dependency, bundled-package, font, icon, and asset notices.
- Modification and source-availability notices added for the new product.
- No-warranty language required by the applicable licenses.

Rebranding can remove Cashew trademarks and product copy from the user-facing identity, but it must not misrepresent authorship or erase required legal attribution.

## Items requiring professional legal review

1. Whether the intended business model is compatible with releasing the full client under GPL-3.0-or-later.
2. Whether any planned proprietary client modules would form a single derivative work and therefore need GPL-compatible licensing.
3. Current Apple and Google store terms, DRM, receipt validation, and signing implications.
4. SaaS/server boundaries for future sync and AI services, including whether client/server components are independent works.
5. Rights to redistribute every bundled font, icon, image, translation, and modified local package.
6. Trademark/trade-dress clearance for the new brand and avoidance of confusion with Cashew.
7. Privacy, financial-data, consumer, subscription, and AI regulations in target jurisdictions.
8. The exact attribution and modification notice presented in-app and in source releases.

## Recommended compliance workflow

Create a release-time Software Bill of Materials and attribution report, retain immutable source tags for every binary, publish Corresponding Source through an owned durable URL, expose license/source links in About and web footers, and make legal review a release gate. Do not remove the current license or notices while this workflow is being designed.

## Phase 1 client/service boundary

Infrastructure separation did not change the client licence. The modified Flutter application remains GPL-3.0-or-later; the root licence, Cashew copyright/provenance, and upstream source link are retained. New branding, commercial distribution, package IDs, and owned Firebase/OAuth projects do not change that conclusion.

Future cloud, account, analytics, or AI services may be independently implemented behind a genuine network/API boundary, but their status depends on architecture and legal facts. Moving covered client code server-side or distributing tightly integrated proprietary client modules is not an automatic licence workaround.

Before release, retain a source tag matching each build, publish complete Corresponding Source/build scripts without secrets, expose GPL/upstream/modification/no-warranty notices, audit all assets/fonts/dependencies, and obtain counsel review of store terms and the client/service boundary. Phase 1 makes no claim of legal clearance.
