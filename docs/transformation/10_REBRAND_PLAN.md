# Rebrand and Figma Readiness Plan

This plan inventories design-system candidates without redesigning them. The goal is to preserve verified financial behavior while allowing a substantially different visual identity.

## Current presentation foundation

Cashew already has reusable shells, navigation, inputs, rows, pickers, dialogs, charts, empty/loading states, color schemes, and typography settings. The limitation is that many widgets mix query/calculation logic with visual rendering. Figma work should begin only after component behavior, states, and data contracts are documented—not by tracing screenshots as if they were the architecture.

## Component map

| Existing Flutter component/family | Purpose | Reusable logic | UI that can change | Candidate Figma component |
|---|---|---|---|---|
| `PageFramework`, `PopupFramework` | Screen/modal structure, padding, safe areas, headers | Layout behavior and responsive constraints | Surfaces, spacing, corner radius, header style | App Page, Sheet/Dialog Shell |
| `PageNavigationFramework`, bottom navigation, sidebar | Primary destinations and responsive navigation | Destination selection and breakpoint behavior | Icons, labels, motion, rail/bar styling | App Shell, Bottom Nav, Navigation Rail |
| Settings container/entry widgets | Grouped settings and toggles | Actions, enabled/disabled state | Row density, dividers, leading/trailing visuals | Settings Section, Settings Row |
| Shared buttons, tappable wrappers, save bar, FAB | Primary/secondary actions and touch feedback | Callbacks, loading/disabled behavior | Shape, typography, hierarchy, elevation | Button set, Icon Button, FAB, Sticky Action Bar |
| Transaction entry/list widgets | Summaries, amounts, categories, selection | Formatting, type/status mapping, selection behavior | Card/row layout, iconography, density | Transaction Row/Card, Selection Toolbar |
| Add/edit transaction controls | Amount, title, date, account, category, recurrence | Validation, parsing, feature workflow | Input composition, progressive disclosure, keyboard flow | Transaction Composer pattern |
| Category icon/entry/picker | Category identity and selection | Hierarchy, selected state, search | Icon containers, color use, chips/grid/list | Category Avatar, Chip, Picker |
| Wallet/account entry and picker | Account identity, currency, balance | Account selection and formatting | Card hierarchy, balance privacy, icons | Account Card, Account Picker Row |
| Budget container/progress widgets | Limit, spend, remaining, period status | Budget calculations and state labels | Progress visualization, card structure, warnings | Budget Card, Progress Meter |
| Objective/goal widgets | Goal/loan progress and linked activity | Progress calculation and actions | Goal card, milestones, imagery | Goal Card, Milestone Progress |
| Search/filter controls | Compose broad transaction filters | Filter model and serialization | Chips, drawer/sheet, result summary | Search Field, Filter Chip, Filter Sheet |
| Date, amount, text and selector inputs | Financial data entry | Parsing, validation, locale/currency behavior | Field styling, error/help content | Form Field family, Amount Input, Date Picker |
| Line, pie, bar and heatmap widgets | Financial trends and composition | Query inputs and value calculation | Chart grammar, labels, interaction, accessibility | Chart Card and chart primitives |
| Snackbar/loading/status/no-results widgets | Feedback and empty/error states | State triggers and retry actions | Illustration, tone, motion, copy | Toast, Progress, Empty State, Error State |
| Bottom sheets/dialogs/confirmation flows | Selection and destructive confirmation | Actions and validation | Surface treatment, content hierarchy | Sheet, Alert, Confirmation Dialog |

Exact widget filenames should be confirmed during each screen's implementation because related components are distributed through `lib/widgets`, feature pages, and settings code.

## Major screen map

| Screen | Logic to preserve | Presentation/design-system opportunity |
|---|---|---|
| Onboarding | Locale, theme, initial account and preference setup | New narrative, trust/privacy explanation, progressive setup |
| Home/dashboard | Balance/spend queries, selected-account scope, shortcuts | New information hierarchy and modular dashboard cards |
| Transactions | Query streams, grouping, selection, filters, type/status logic | New row/card anatomy, density modes, accessible amount semantics |
| Add/edit transaction | Validation, transfer pairing, recurrence, goal/budget effects, attachments | Task-focused composer and clearer advanced options |
| Budgets | Period/limit calculations, filters, category limits, history | New budget cards, progress language, warning hierarchy |
| Accounts | Wallet balances, currencies, archive/type behavior, transfers | New account identity, privacy mode, asset/liability readiness |
| Analytics | Existing aggregations, periods, category/account scope | Consistent chart grammar, explanations, accessible alternatives |
| Recurring transactions | Schedule, due/paid/auto-pay state and notifications | Timeline/calendar pattern and predictable status controls |
| Search | Query parsing and broad `SearchFilters` model | Unified search, visible active filters, saved-filter readiness |
| Settings | Existing preferences, security, backup/sync, integrations | Reorganized information architecture and risk/permission explanations |

## Logic/presentation separation rules

1. Capture current behavior with tests before moving it.
2. Define typed view data for money, dates, account/category identity, progress, and loading/error/empty states.
3. Keep Drift rows and Firebase documents out of new visual component APIs.
4. Move calculations to pure functions/application services when a screen is redesigned; do not migrate unrelated features opportunistically.
5. Make components render all states in isolation: default, selected, loading, empty, error, disabled, archived, overdue, and privacy-hidden.
6. Keep accessibility semantics, dynamic text scaling, localization expansion, RTL review, keyboard/focus behavior, and contrast in component acceptance criteria.
7. Map each approved Figma component to one canonical Flutter component and document intentional platform variants.

## Figma preparation package

Before visual exploration, prepare:

- approved new name, trademark clearance, product principles, audience, and accessibility target;
- content inventory and terminology decisions (account vs wallet, goal vs objective, recurring vs subscription);
- screenshots and state matrix from a verified baseline build using synthetic data only;
- token inventory for color roles, typography, spacing, radius, elevation, motion, icon sizes, and chart semantics;
- component inventory above with variants and interaction rules;
- screen flows for onboarding, first transaction, transfer, budget creation, restore, sign-in/sharing, and error recovery;
- localization length/RTL test cases and platform safe-area/navigation constraints;
- a decision log identifying financial logic that is frozen during visual redesign.

## Rebrand implementation controls

Use a manifest that lists every name, icon, URL, package ID, OAuth/Firebase identifier, store product, permission description, and legal notice. Each entry needs an owner, target environment, verification method, and rollback/compatibility note. Visual tokens may be replaced broadly once their coverage is verified; identifiers and data-facing names require staged migrations and device testing.

No Figma file or redesigned screen should be created until the user approves the next phase and supplies the brand/product inputs listed in the roadmap.
