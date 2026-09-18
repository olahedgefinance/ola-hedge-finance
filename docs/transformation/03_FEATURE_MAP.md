# Feature Inventory

Classification is a transformation recommendation, not an instruction to remove or implement anything now.

| Feature | Purpose and principal modules | Dependencies | Recommendation |
|---|---|---|---|
| Onboarding | Initial preferences, accounts, and first-run flow in onboarding pages and `main.dart` | Settings, wallets, localization | MODIFY — retain setup logic; redesign content and flow |
| Dashboard/home | Balances, spending summaries, recent activity, charts, shortcuts | Drift wallet/transaction queries, chart widgets, settings | MODIFY — retain queries/calculations; replace presentation |
| Transactions | Create, edit, delete, duplicate, batch-select, transfer, balance correction, attachments | Transactions, wallets, categories, objectives, file/image APIs | KEEP — core reusable capability; add regression tests first |
| Accounts/wallets | Multi-account balances, currencies, formatting, transfers, account detail | Wallet and transaction tables, currency data, home widgets | KEEP — rename UI terminology as required |
| Categories | Categories, subcategories, icons, emoji, colors, inferred associated titles | Category and associated-title tables, assets | KEEP — visually retheme and validate inference rules |
| Budgets | Repeating periods, category/account scope, category limits, archives, history, income options | Budgets, category limits, transactions, wallets | KEEP — mature and central; isolate calculations before redesign |
| Shared budgets | Email-based membership and Firestore transaction sharing | Firebase Auth, Firestore, original security configuration | REVIEW — valuable but needs a new security/identity design |
| Recurring/upcoming transactions | Repetition schedules, subscriptions, due dates, auto-create/auto-pay | Transaction fields, startup jobs, local notifications | KEEP — verify timezone and idempotency behavior |
| Goals/objectives | Savings goals and loan objectives linked to transactions | Objectives, wallets, transactions | MODIFY — reusable base for a broader goals/debt module |
| Credit/debt views | Track credit and debt transaction types | Transactions, wallets, goals | MODIFY — extend only after defining account/debt domain models |
| Search and filters | Text, dates, amounts, wallets, categories, budgets, goals, types, paid state | Drift data and `SearchFilters` helpers | KEEP — broad reusable behavior |
| Analytics | Line, pie, bar, heatmap, budget history, all-spending views | Drift queries and chart widgets | MODIFY — retain data logic; redesign chart components/accessibility |
| Imports | CSV and public Google Sheets CSV imports | File picker, HTTP, parsing/mapping UI | REVIEW — retain with validation, preview, and error-report hardening |
| Exports | CSV exports and raw database export | File sharing/storage, Drift | KEEP — document formats and add privacy warnings |
| Backup and restore | Local raw-database export/import and Google Drive backup | SQLite/IndexedDB, Drive API, file picker | REVIEW — critical value; add integrity and compatibility checks |
| Device sync | Per-client database files, timestamps, tombstones, row merge | Drive appDataFolder, DeleteLogs, modification timestamps | REVIEW — test conflicts and data loss cases before production |
| Email scanning | Create transactions from Gmail using scanner templates | Google Sign-In, Gmail read/modify scopes, scanner templates | REVIEW — high privacy/consent burden |
| Android notification scanning | Parse selected dismissed notifications into transactions | Notification-listener permission/service, templates | REVIEW — Android-only and privacy sensitive |
| Local notifications | Upcoming/overdue, budget, recurring, and reminder scheduling | Local notifications, timezone, boot receiver | KEEP — replace channels/text and test platform behavior |
| Biometrics | Gate application access | `local_auth`, platform usage descriptions | KEEP — clarify it is an app gate, not database encryption |
| Localization | Runtime locale selection and translated JSON assets | EasyLocalization, custom asset loader | KEEP — preserve key system and refresh translations |
| Themes and accessibility | Light/dark/system colors, Material You, fonts, density choices | Theme extensions, font assets, settings | REPLACE — new design tokens may replace visuals while retaining settings logic |
| Home widgets | Account/budget information on Android/iOS widgets | Home-widget package, platform code, settings | REVIEW — rebrand and reassess privacy on locked screens |
| Quick actions/app links | Fast add/open routes and deep-linked navigation | Platform manifests, domains, navigation globals | MODIFY — replace identifiers/domains and use typed destinations |
| Premium/IAP | Monthly, annual, lifetime purchases and paywall | Store product identifiers, IAP, original entitlement logic | REVIEW — requires a new commercial model and store setup |
| Donations/support | Links to Cashew support and donation properties | External URLs | REMOVE — from the new product after licensing/legal review |
| Activity/change logs | Surface data updates/deletes and support sync | Update timestamps and DeleteLogs | KEEP — useful for trust and support |
| Bill splitting | Split an amount among participants | UI/calculation helpers | KEEP — low-coupling reusable utility |

## Important module locations

- Transaction flows: `budget/lib/pages/addTransactionPage.dart`, transaction pages, and transaction widgets.
- Accounts: wallet pages, wallet selection widgets, and `TransactionWallet` queries.
- Budgets: budget pages/widgets plus `Budgets` and `CategoryBudgetLimits` tables.
- Categories: category pages/widgets, `Categories`, and `AssociatedTitles`.
- Recurrence and due dates: transaction recurrence helpers, startup processing, and notification scheduling.
- Search: transaction search page/widgets and `SearchFilters` structures.
- Analytics: graph widgets, wallet details, all-spending, and budget-history views.
- Import/export: import pages and CSV/database backup helpers under pages/struct/settings.
- Cloud: Firebase helpers, shared-budget code, Google API helpers, and Drive/Gmail flows.

## Reuse assessment

The strongest reusable assets are the schema and migration history, transaction/account/category/budget workflows, recurrence behavior, broad search filters, multi-currency handling, import/export logic, and financial queries. The weakest candidates for direct reuse are Cashew-branded presentation, globally coupled navigation, the current cloud deployment configuration, unverified sync/conflict behavior, and the existing premium/support setup.

No feature should be removed solely because it is classified `REMOVE` or `REPLACE`; those decisions belong to later approved phases and must preserve GPL obligations and user-data compatibility.
