# ÓLA navigation shell — Phase 6A

`OlaAppShell` is a presentation wrapper around the existing `FadeIndexedStack`.
The existing Navigator, numbered destinations, startup, deep-link handlers,
financial pages, database and Android Back handler retain their identities.

| Section | Existing page IDs |
|---|---|
| Home | 0 Home |
| Money | 1 Transactions, 9 financial Accounts, 5 Subscriptions, 16 Scheduled |
| Plan | 2 Budgets, 14 Goals |
| Wealth | 7 existing All Spending analytics, 17 Loans |

Settings accepts existing route IDs 3/4 but renders the single keyed settings page at index 3, preventing duplicate login GlobalKeys. More retains notifications, sign-in account (8),
budget/category/title/goal management and About, plus the saved custom shortcuts.
Shortcut aliases 3/4 are shown once in More; the legacy stack retains both IDs.
The existing shortcut picker remains available for all three stored slots.
Switching sections remembers the last visited sibling for the current session.

Figma: `Jk52FLNwpBjNo7JtXzqNYq`, Navigation 9:48, Home 16:3,
Responsive 40:3, Light/Dark 37:3. Verified: four section labels, bottom navigation,
220px expanded sidebar, Inter, semantic selected states and 24px navigation insets.
Figma has no breakpoint or complete legacy route mapping. Implementation choices:
retain 700px threshold and 70px collapsed preference; minimum 48px Android targets;
retain the full available page area and existing screen headers/insets pending
their Phase 6 slices. Toolbar search/settings and sibling tabs keep old flows reachable.

No new assets are imported. Existing cleared Material icons replace the generic
Figma marker icons. Tested Phase 5A text contrast roles take precedence over raw
Emerald text on white; the existing dark surface and saved theme preferences remain.
New section names Money/Plan/Wealth and Analytics currently use English. Existing
destination labels use existing translations. Frozen localization evidence stays
unchanged; supplemental translations can be added in a later localization slice.

The shell is enabled by default. `--dart-define=OLA_PHASE6_UI=false` retains the
inherited layout for diagnosis without migrating preferences. DEV-only branding
and public release guards remain active in both layouts. No religious imagery,
security claims or new financial modules are introduced.

The page boundary clips inherited pull-to-refresh transforms so they cannot paint
over the shell's sibling tabs. The financial page subtree still receives the full
available width; it retains its own responsive content constraints. Mobile bar
height measures wrapped translated labels, including at large text scales.
