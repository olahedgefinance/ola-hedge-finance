# ÓLA Home Dashboard — Phase 6B

Internal Android MVP; public release remains blocked. Base: `6282c0a26045dfa08bd3a8a0292b671974926cd2`.

## Implementation map and ownership

The implementation map was prepared before edits. `HomePage` retains its state key, scroll controller, sync, transaction selection, section visibility/order settings and route callbacks. The Phase 6A shell still owns navigation. `OlaDashboardScope` changes presentation only within Home; no new database, calculation, authentication or service layer is introduced.

| Section | Existing source and behavior |
| --- | --- |
| Financial overview | `HomePageNetWorth`, pinned/all-wallet and period settings, `watchTotalWithCountOfWallet`, existing currency conversion and money formatter |
| Financial Health | `HomePageAllSpendingSummary`: recorded income and expense totals for the selected accounts and period; no score or diagnostic classification |
| Accounts | `HomePageWalletList` / optional wallet switcher; original balance streams, currency precision, selection, detail and edit actions |
| Budget progress | `HomePageBudgets`, `BudgetContainer`; original pinned budgets, current-period spending, percentages and remaining-per-day calculations |
| Savings goals | `HomePageObjectives(ObjectiveType.goal)`; original linked paid transactions and target progress |
| Upcoming and overdue | `HomePageUpcomingTransactions`; original scheduled-payment streams, refresh timer and Scheduled detail route |
| Recent transactions | `HomeTransactions` and `TransactionEntries`; original filters, selection, future-day preference, seven-day display limit and 50-per-day limit |
| Optional modules | Existing chart, currency breakdown, lent/borrowed and loan widgets remain available through Customize |

New-install defaults expose the MVP sections. Existing saved visibility, pinned accounts, periods and order are **not reset**. Existing users can enable hidden sections using Customize dashboard. Detail pages retain their inherited behavior and styling.

## Reusable presentation

`widgets/ola/ola_dashboard.dart` supplies the header, section, metric card, responsive metric pair, content container and loading/error presentation. It receives formatted facts and callbacks, not raw financial models. Amount boxes opt into this presentation only inside Home. The two-stream amount builder has an opt-in completeness/error mode; other callers keep their original behavior.

Accounts wrap full names and amounts; currency-breakdown percentages retain the existing formatter. Budget and transaction stream failures surface Home-only errors instead of blank/loading content. Empty budgets/goals reuse the existing add actions; zero totals explicitly say there are no recorded transactions. These are presentation changes, not changes to paid/unpaid counting semantics.

## Verified Figma reference and adaptations

Primary reference: https://www.figma.com/design/Jk52FLNwpBjNo7JtXzqNYq

- Home `16:3`: 390×844, 24px side inset, “Your financial health”, net-worth hero, metric summaries, attention/insight areas and four primary mobile destinations.
- Metric `6:37`: positive/neutral/negative variants, label/value/context, 16px radius, 20px inset and 10px internal spacing.
- Responsive `40:3` / desktop Home `40:11`: 1440×900, 220px sidebar, 48px content inset and compact/wide arrangements.
- Light/dark `37:3` supplied appearance references.

Phase 5A accessible theme tokens remain authoritative: Inter, approved semantic colors, 16px regular-card inset and 24px hero inset, restrained borders. The metric inset deliberately uses the approved 16px spacing token rather than the prototype's 20px; this is an adaptation, not claimed pixel parity. Cards grow naturally for large text. Metric pairs stack below 300px available width or above 130% text scale. Dashboard groups use two columns at 960px available content width and a 1200px maximum container; exact breakpoints/max width were not specified by Figma and are implementation choices. Phase 6A navigation thresholds are unchanged.

Budgets, goals, charts and transactions reuse existing widgets rather than recreating prototype example data. The prototype's savings rate, credit utilization/payment advice, growth/streak badges and “on track” goal classification lack approved calculation definitions and are omitted. No financial formula or numerical Financial Health score was introduced. A future task must obtain owner approval for any such calculation before implementation.

“Wealth under protection” expresses the brand idea without religious imagery or a financial-security guarantee. INTERNAL DEVELOPMENT and the existing demo warning remain explicit. No artwork, font files, identifiers or release approvals change.

## Validation boundaries and follow-up

Dashboard tests cover formatted amount parity, stream loading/error/recovery, responsive layouts through 200% text, long account names/amounts, currency percentages, saved legacy presentation and a 5,003-record database fixture. The full existing financial and navigation suites remain required. Browser preview verifies the live composition and detail navigation; it does not replace physical Android performance/assistive-technology testing.

New explanatory dashboard copy currently has an English fallback, as the Phase 6A shell does. Localized existing amount labels and legacy screens remain intact; a separate localization overlay should translate new copy without rewriting frozen translation assets. Some inherited chart, goal and detailed-screen typography remains to be refined in Phase 6C. Do not treat this MVP as a comprehensive accessibility or production-release certification.
