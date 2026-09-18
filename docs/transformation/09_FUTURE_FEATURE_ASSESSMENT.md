# Future Feature Assessment

The classifications assume the existing Drift foundation is retained, migrations are protected by tests, and presentation is separated incrementally. They describe architecture effort, not product-design effort.

| Proposed module | Classification | Architectural reason and likely work |
|---|---|---|
| Net worth | MODERATE EXTENSION | Current wallet totals provide a basic net position, but true net worth needs asset/liability types, valuation dates, ownership, currency conversion policy, and historical snapshots |
| Assets | MODERATE EXTENSION | Add typed assets and valuations or evolve wallet types; requires new tables, valuation history, edit flows, and analytics without overloading transactions |
| Liabilities | MODERATE EXTENSION | Existing negative balances/loan objectives help, but principal, rates, terms, payments, statements, and payoff projections need a liability model |
| Debt management | MODERATE EXTENSION | Credit/debt transaction views and loan objectives are reusable; amortization, payoff strategies, interest accrual, minimums, and lender schedules require domain services and schema |
| Credit-card utilization | MODERATE EXTENSION | Requires credit limits, statement/reporting dates, posted/pending semantics, per-card utilization, and bureau-oriented aggregation absent from wallets today |
| Financial goals | EASY EXTENSION | Objectives already support goals and linked transactions; richer targets, milestones, and forecasting can build on them after calculation tests |
| Emergency fund tracking | EASY EXTENSION | Can specialize objectives and derive coverage from categories/spending; needs configurable essential-expense rules rather than a new architecture |
| Cash-flow forecasting | MODERATE EXTENSION | Recurring/upcoming transactions provide inputs, but a deterministic projection engine, scenario model, timezone policy, and confidence handling are needed |
| Investment tracking | MAJOR ARCHITECTURAL CHANGE | Holdings, instruments, lots, corporate actions, prices, returns, fees, and market-data services do not fit the current wallet/transaction model cleanly |
| Household/shared finances | MAJOR ARCHITECTURAL CHANGE | Sharing is budget-scoped and email-based; a household/tenant model, roles, invitations, ownership, conflict resolution, audit, and secure server authority are required |
| Financial health dashboard | MODERATE EXTENSION | Existing queries/charts are reusable, but metrics need a tested calculation layer, normalized definitions, snapshots, and explainable scoring |
| AI financial assistant | MAJOR ARCHITECTURAL CHANGE | Requires a secure backend boundary, consent, minimization/redaction, retrieval permissions, prompt/tool policy, audit trails, deletion, cost/rate controls, and defenses against unsafe financial advice |

## Cross-cutting prerequisites

Before any major module is built:

- create a migration fixture and financial invariant test suite;
- introduce typed account, transaction, money/currency, date-range, and identity interfaces around existing data;
- move calculations out of widgets into pure/application services as each area is touched;
- define offline, multi-device, and conflict semantics;
- decide whether household/cloud data remains local-first or becomes server-authoritative;
- establish privacy classification, retention, export, and deletion for every new field;
- instrument behavior only after consent and observability policy are approved.

## Recommended sequence

The lowest-risk additions are richer goals and emergency-fund tracking because they can extend `Objectives` and existing spending calculations. Cash-flow forecasting and the health dashboard should follow once recurrence and analytics calculations are isolated and tested. Assets, liabilities, debt, and credit-card utilization should be designed together so they share a coherent account/valuation model. Household sharing, investments, and AI should wait for explicit cloud/security architecture rather than being added to the current client-driven integration pattern.

## AI-specific boundary

An AI assistant must not receive the whole raw database by default. A future design should expose narrowly scoped, deterministic tools such as “summarize spending for an approved period,” with explicit user confirmation for sensitive or mutating actions. Calculations should remain auditable application services; the model should explain results, not become the unverified system of record or execute transactions autonomously.
