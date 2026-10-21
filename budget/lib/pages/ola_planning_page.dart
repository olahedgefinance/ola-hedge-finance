import 'package:budget/widgets/ola/ola_focus_outline.dart';
import 'package:budget/brand/ola_theme.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/planning_mvp.dart';
import 'package:budget/widgets/ola/transaction_safety_widgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

String planningMoney(AllWallets wallets, String walletPk, double amount) {
  final wallet = wallets.indexedByPk[walletPk];
  final currency = wallet?.currency;
  if (currency == null || currency.isEmpty) return 'Currency unavailable';
  if (!amount.isFinite) return 'Amount unavailable';
  return convertToMoney(wallets, amount,
      currencyKey: currency, decimals: wallet!.decimals, addCurrencyName: true);
}

String _date(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatShortDate(date);

/// Small reusable state boundary: errors never become zero financial values.
class PlanningData<T> extends StatefulWidget {
  const PlanningData({super.key, required this.load, required this.builder});
  final Stream<T> Function() load;
  final Widget Function(T data) builder;
  @override
  State<PlanningData<T>> createState() => _PlanningDataState<T>();
}

class _PlanningDataState<T> extends State<PlanningData<T>> {
  late Stream<T> stream = widget.load();
  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Unable to load planning data. No total is available.'),
                TextButton(
                    onPressed: () => setState(() => stream = widget.load()),
                    child: const Text('Retry'))
              ]);
        }
        if (!snapshot.hasData) {
          return Semantics(
              liveRegion: true, child: const Text('Loading planning data…'));
        }
        return widget.builder(snapshot.data as T);
      });
}

class OlaPlanningPage extends StatefulWidget {
  const OlaPlanningPage(
      {super.key, required this.db, this.date, this.enableBackButton = false});
  final FinanceDatabase db;
  final DateTime? date;
  final bool enableBackButton;
  @override
  State<OlaPlanningPage> createState() => OlaPlanningPageState();
}

class OlaPlanningPageState extends State<OlaPlanningPage> {
  final controller = ScrollController();
  late DateTime selectedDate = widget.date ?? DateTime.now();
  void scrollToTop() {
    if (controller.hasClients) {
      controller.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Plan'),
          automaticallyImplyLeading: widget.enableBackButton),
      body: PlanningData<AllWallets>(
          load: widget.db.watchAllWalletsIndexed,
          builder: (wallets) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Budgets',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text(
                        'Individual budgets may overlap. Amounts are shown in each budget’s native currency.'),
                    Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                                'Period containing ${_date(context, selectedDate)}'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2200));
                              if (date != null && mounted) {
                                setState(() => selectedDate =
                                    date.add(const Duration(hours: 12)));
                              }
                            })),
                    Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _Action(
                            label: 'Create budget',
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => PlanningBudgetEditor(
                                        db: widget.db, wallets: wallets))))),
                    const SizedBox(height: 16),
                    PlanningData<List<Budget>>(
                        load: () =>
                            widget.db.watchAllBudgets(hideArchived: true),
                        builder: (budgets) => Column(children: [
                              if (budgets.isEmpty)
                                const _Panel(child: Text('No budgets yet')),
                              for (final budget in budgets)
                                PlanningBudgetCard(
                                    key: ValueKey(
                                        '${budget.toJson()}-$selectedDate-${wallets.list}'),
                                    db: widget.db,
                                    budget: budget,
                                    wallets: wallets,
                                    date: selectedDate),
                            ])),
                    const SizedBox(height: 24),
                    Text('Upcoming & recurring',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Text(
                        'Saved unpaid payments, including overdue items. Dates are stored schedules, not forecasts.'),
                    PlanningData<List<Transaction>>(
                        load: () =>
                            widget.db.watchAllOverdueUpcomingTransactions(null),
                        builder: (rows) => Column(children: [
                              if (rows.isEmpty)
                                const _Panel(
                                    child: Text('No scheduled payments')),
                              for (final row in rows)
                                _TransactionTile(
                                    row: row,
                                    wallets: wallets,
                                    db: widget.db,
                                    scheduled: true),
                            ])),
                    const SizedBox(height: 24),
                    Text('Goals',
                        style: Theme.of(context).textTheme.titleLarge),
                    PlanningData<List<Objective>>(
                        load: () => widget.db.watchAllObjectives(
                            objectiveType: ObjectiveType.goal,
                            hideArchived: true),
                        builder: (goals) => Column(children: [
                              if (goals.isEmpty)
                                const _Panel(child: Text('No saved goals')),
                              for (final goal in goals)
                                _Panel(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(goal.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                          'Saved target: ${planningMoney(wallets, goal.walletFk, goal.amount)}'),
                                      PlanningData<List<Transaction>>(
                                          key: ValueKey(
                                              '${goal.toJson()}-${wallets.list}'),
                                          load: () =>
                                              watchPlanningGoalTransactions(
                                                  widget.db, goal),
                                          builder: (rows) {
                                            final progress = nativeGoalProgress(
                                                goal, rows, wallets);
                                            return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (progress == null)
                                                    const Text(
                                                        'Exchange rate unavailable. Goal progress is withheld.')
                                                  else ...[
                                                    Text(
                                                        'Progress: ${planningMoney(wallets, goal.walletFk, progress)}'),
                                                    if (goal.amount > 0)
                                                      LinearProgressIndicator(
                                                          value: (progress /
                                                                  goal.amount)
                                                              .clamp(0.0, 1.0),
                                                          semanticsLabel:
                                                              '${goal.name} goal progress',
                                                          semanticsValue:
                                                              '${planningMoney(wallets, goal.walletFk, progress)} of ${planningMoney(wallets, goal.walletFk, goal.amount)}'),
                                                  ],
                                                  const Text(
                                                      'Goal editing is unavailable in this internal MVP.'),
                                                ]);
                                          }),
                                    ])),
                            ])),
                    const SizedBox(height: 80),
                  ])));
}

class PlanningBudgetCard extends StatelessWidget {
  const PlanningBudgetCard(
      {super.key,
      required this.db,
      required this.budget,
      required this.wallets,
      required this.date});
  final FinanceDatabase db;
  final Budget budget;
  final AllWallets wallets;
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final range = getBudgetDate(budget, date);
    return _Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(budget.name, style: Theme.of(context).textTheme.titleLarge),
      Text(planningBudgetUsesAllDates(budget)
          ? 'All dates · manually assigned transactions'
          : '${_date(context, range.start)} – ${_date(context, range.end)}'),
      Text('Budget: ${planningMoney(wallets, budget.walletFk, budget.amount)}'),
      Text(
          'Included accounts: ${(budget.walletFks?.isNotEmpty ?? false) ? budget.walletFks!.map((pk) => wallets.indexedByPk[pk]?.name ?? "Account unavailable").join(", ") : "All accounts"}'),
      PlanningData<List<Transaction>>(
          load: () => watchPlanningBudgetTransactions(db, budget, date),
          builder: (rows) {
            final spent = nativeBudgetSpending(budget, rows, wallets);
            final remaining = spent == null ? null : budget.amount - spent;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  if (spent == null)
                    Semantics(
                        liveRegion: true,
                        child: const Text(planningRateUnavailable))
                  else ...[
                    Text(
                        '${budget.income ? "Income" : "Spent"}: ${planningMoney(wallets, budget.walletFk, spent)}'),
                    Text(
                        '${budget.income ? (remaining! < 0 ? "Above target" : "Remaining to target") : (remaining! < 0 ? "Overspent" : "Remaining")}: ${planningMoney(wallets, budget.walletFk, remaining.abs())}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: budget.amount > 0
                            ? (spent / budget.amount).clamp(0.0, 1.0)
                            : 0,
                        semanticsLabel: '${budget.name} budget progress',
                        semanticsValue:
                            '${planningMoney(wallets, budget.walletFk, spent)} of ${planningMoney(wallets, budget.walletFk, budget.amount)}'),
                  ],
                  Wrap(spacing: 8, children: [
                    TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => _BudgetTransactions(
                                    db: db,
                                    budget: budget,
                                    wallets: wallets,
                                    date: date))),
                        child: const Text('View transactions')),
                    if (canEditPlanningBudget(budget))
                      TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => PlanningBudgetEditor(
                                      db: db,
                                      wallets: wallets,
                                      original: budget))),
                          child: const Text('Edit budget')),
                  ]),
                  if (!canEditPlanningBudget(budget))
                    const Text(
                        'Shared and advanced budgets are read-only here.'),
                ]);
          }),
    ]));
  }
}

class _BudgetTransactions extends StatelessWidget {
  const _BudgetTransactions(
      {required this.db,
      required this.budget,
      required this.wallets,
      required this.date});
  final FinanceDatabase db;
  final Budget budget;
  final AllWallets wallets;
  final DateTime date;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(budget.name)),
      body: PlanningData<List<Transaction>>(
          load: () => watchPlanningBudgetTransactions(db, budget, date),
          builder: (rows) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                Text(
                    '${rows.length} paid transactions ${planningBudgetUsesAllDates(budget) ? "across all dates" : "in this budget period"}'),
                if (rows.isEmpty) const Text('No matching transactions'),
                for (final row in rows)
                  _TransactionTile(db: db, row: row, wallets: wallets),
              ])));
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(
      {required this.db,
      required this.row,
      required this.wallets,
      this.scheduled = false});
  final FinanceDatabase db;
  final Transaction row;
  final AllWallets wallets;
  final bool scheduled;
  @override
  Widget build(BuildContext context) => _Panel(
      child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(row.name),
          subtitle: Text(
              '${nativeTransactionAmount(wallets, row)}\n${wallets.indexedByPk[row.walletFk]?.name ?? "Account unavailable"} · ${_date(context, row.dateCreated)}${scheduled ? " · ${row.type?.name ?? 'Scheduled'}${row.dateCreated.isBefore(DateTime.now()) ? ' · Overdue' : ''}" : ""}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final category = await db.getCategoryInstanceOrNull(row.categoryFk);
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ReadOnlyTransactionDetails(
                    transaction: row,
                    wallets: wallets,
                    categoryName: category?.name,
                    reason:
                        'Read-only planning details. Use Transactions for supported edits. Linked-transfer safeguards remain in effect.')));
          }));
}

class PlanningBudgetEditor extends StatefulWidget {
  const PlanningBudgetEditor(
      {super.key, required this.db, required this.wallets, this.original});
  final FinanceDatabase db;
  final AllWallets wallets;
  final Budget? original;
  @override
  State<PlanningBudgetEditor> createState() => _PlanningBudgetEditorState();
}

class _PlanningBudgetEditorState extends State<PlanningBudgetEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.original?.name ?? '');
  late final amount =
      TextEditingController(text: widget.original?.amount.toString() ?? '');
  late final interval = TextEditingController(
      text: (widget.original?.periodLength ?? 1).toString());
  late String? walletPk = widget.original?.walletFk;
  late DateTime start = widget.original?.startDate ??
      DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime end = widget.original?.endDate ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  late BudgetReoccurence recurrence =
      widget.original?.reoccurrence ?? BudgetReoccurence.monthly;
  late Set<String> categories = {...?widget.original?.categoryFks};
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    interval.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final original = widget.original;
      final base = original ??
          Budget(
              budgetPk: '-1',
              name: '',
              amount: 0,
              startDate: start,
              endDate: end,
              walletFk: walletPk!,
              walletFks: [walletPk!],
              income: false,
              archived: false,
              addedTransactionsOnly: false,
              periodLength: 1,
              reoccurrence: BudgetReoccurence.monthly,
              dateCreated: DateTime.now(),
              pinned: false,
              order: await widget.db.getAmountOfBudgets(),
              isAbsoluteSpendingLimit: false,
              budgetTransactionFilters: const [
                BudgetTransactionFilters.defaultBudgetTransactionFilters
              ]);
      final draft = base.copyWith(
          name: name.text.trim(),
          amount: double.parse(amount.text),
          startDate: start,
          endDate: end,
          reoccurrence: Value(recurrence),
          periodLength: recurrence == BudgetReoccurence.custom
              ? 1
              : int.parse(interval.text),
          categoryFks: Value(categories.isEmpty ? null : categories.toList()));
      await savePlanningBudget(widget.db, draft,
          original: original,
          expectedCurrency: widget.wallets.indexedByPk[walletPk]?.currency);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => error = e is PlanningException
            ? e.message
            : 'Unable to save this budget. Try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: isStart ? start : end,
        firstDate: DateTime(1900),
        lastDate: DateTime(2200));
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title:
              Text(widget.original == null ? 'Create budget' : 'Edit budget')),
      body: Form(
          key: form,
          child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                    controller: name,
                    enabled: !busy,
                    maxLength: 250,
                    decoration: _planningInput(context, 'Budget name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a budget name'
                        : null),
                const SizedBox(height: 16),
                if (widget.original == null)
                  DropdownButtonFormField<String>(
                      value: walletPk,
                      isExpanded: true,
                      decoration:
                          _planningInput(context, 'Account and currency'),
                      items: [
                        for (final w in widget.wallets.list
                            .where((w) => w.currency?.isNotEmpty ?? false))
                          DropdownMenuItem(
                              value: w.walletPk,
                              child: Text(
                                  '${w.name} · ${w.currency!.toUpperCase()}'))
                      ],
                      onChanged:
                          busy ? null : (v) => setState(() => walletPk = v),
                      validator: (v) => v == null ? 'Select an account' : null)
                else
                  Text(
                      'Currency and included accounts are unchanged. Budget currency: ${widget.wallets.indexedByPk[walletPk]?.currency?.toUpperCase() ?? "unavailable"}'),
                if (widget.original == null)
                  const Text(
                      'This budget includes spending from this account only.'),
                const SizedBox(height: 16),
                TextFormField(
                    controller: amount,
                    enabled: !busy,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _planningInput(
                        context, 'Budget amount (native currency)'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return n == null ||
                              !n.isFinite ||
                              n <= 0 ||
                              n >= 999999999999
                          ? 'Enter a positive amount below 999999999999'
                          : null;
                    }),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetReoccurence>(
                    value: recurrence,
                    decoration: _planningInput(context, 'Budget period'),
                    items: [
                      for (final p in BudgetReoccurence.values)
                        DropdownMenuItem(value: p, child: Text(p.name))
                    ],
                    onChanged:
                        busy ? null : (v) => setState(() => recurrence = v!)),
                if (recurrence != BudgetReoccurence.custom)
                  TextFormField(
                      controller: interval,
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      decoration: _planningInput(context, 'Number of periods'),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null || int.parse(v!) < 1
                              ? 'Enter a positive whole number'
                              : null),
                TextButton(
                    onPressed: busy ? null : () => pickDate(true),
                    child: Text('Start: ${_date(context, start)}')),
                if (recurrence == BudgetReoccurence.custom)
                  TextButton(
                      onPressed: busy ? null : () => pickDate(false),
                      child: Text('End: ${_date(context, end)}')),
                const SizedBox(height: 16),
                Text('Spending categories',
                    style: Theme.of(context).textTheme.titleMedium),
                const Text(
                    'No selection includes all categories allowed by the budget’s existing filters.'),
                PlanningData<List<TransactionCategory>>(
                    load: () =>
                        widget.db.watchAllCategories(selectedIncome: false),
                    builder: (items) => Column(children: [
                          for (final c in items)
                            CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(c.name),
                                subtitle: (widget.original?.categoryFksExclude
                                            ?.contains(c.categoryPk) ??
                                        false)
                                    ? const Text('Excluded by this budget')
                                    : null,
                                value: categories.contains(c.categoryPk),
                                onChanged: busy ||
                                        (widget.original?.categoryFksExclude
                                                ?.contains(c.categoryPk) ??
                                            false)
                                    ? null
                                    : (v) => setState(() {
                                          if (v == true) {
                                            categories.add(c.categoryPk);
                                          } else {
                                            categories.remove(c.categoryPk);
                                          }
                                        })),
                        ])),
                if (error != null)
                  Semantics(
                      liveRegion: true,
                      child: Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 24),
                _Action(
                    label: busy ? 'Saving…' : 'Save budget',
                    onPressed: busy ? null : save),
                const SizedBox(height: 32),
              ])));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(16), child: child));
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OlaSemanticColors>() ??
        OlaSemanticColors.forBrightness(Theme.of(context).brightness);
    return OlaFocusOutline(
        radius: BorderRadius.circular(24),
        child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: tokens.actionBackground,
                foregroundColor: tokens.actionForeground,
                minimumSize: const Size(48, 48)),
            onPressed: onPressed,
            child: Text(label)));
  }
}

InputDecoration _planningInput(BuildContext context, String label) {
  final theme = Theme.of(context);
  final roles = theme.extension<OlaSemanticColors>() ??
      OlaSemanticColors.forBrightness(theme.brightness);
  return InputDecoration(
      labelText: label,
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.outline)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: roles.focusVisible, width: 2)),
      errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: roles.focusVisible, width: 2)));
}
