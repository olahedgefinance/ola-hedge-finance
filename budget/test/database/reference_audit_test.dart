import 'package:budget/database/reference_audit.dart';
import 'package:budget/database/tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

void main() {
  late FinanceDatabase db;

  setUp(() async {
    db = await createTestDatabase();
    await seedWalletAndCategories(db);
    await db.into(db.objectives).insert(fixtureObjective());
    await db.into(db.budgets).insert(
          fixtureBudget(
            walletFks: const <String>['wallet-a', 'wallet-b'],
            categoryFks: const <String>['category-expense'],
          ),
        );
  });

  tearDown(() => db.close());

  test('valid declared and serialized relationships pass the audit', () async {
    await db.into(db.transactions).insert(
          fixtureTransaction(objectiveFk: 'objective-1'),
        );

    final audit = await auditDatabaseReferences(db);

    expect(audit.isValid, isTrue);
    expect(audit.totalViolations, 0);
    expect(audit.violations, isEmpty);
  });

  test('audit classifies every unsafe financial relationship', () async {
    await db.customStatement(
      'INSERT INTO transactions '
      '(transaction_pk, name, amount, note, category_fk, sub_category_fk, '
      'wallet_fk, date_created, income, paid, skip_paid, paired_transaction_fk, '
      'objective_fk, objective_loan_fk, shared_reference_budget_pk, '
      'budget_fks_exclude) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'orphan-transaction',
        'Orphan',
        -10.0,
        '',
        'missing-category',
        'missing-subcategory',
        'missing-wallet',
        fixtureDate.millisecondsSinceEpoch ~/ 1000,
        0,
        1,
        0,
        'missing-pair',
        'missing-objective',
        'missing-loan',
        'missing-budget',
        '["missing-budget"]',
      ],
    );
    await db.customStatement(
      'UPDATE categories SET main_category_pk = ? WHERE category_pk = ?',
      <Object?>['missing-parent', 'category-expense'],
    );
    await db.customStatement(
      'UPDATE budgets SET wallet_fk = ?, wallet_fks = ?, category_fks = ?, '
      'category_fks_exclude = ? WHERE budget_pk = ?',
      <Object?>[
        'missing-wallet',
        '["missing-wallet"]',
        '["missing-category"]',
        '["missing-category"]',
        'budget-1',
      ],
    );
    await db.customStatement(
      'UPDATE objectives SET wallet_fk = ? WHERE objective_pk = ?',
      <Object?>['missing-wallet', 'objective-1'],
    );
    await db.customStatement(
      'INSERT INTO category_budget_limits '
      '(category_limit_pk, category_fk, budget_fk, amount, wallet_fk) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        'orphan-limit',
        'missing-category',
        'missing-budget',
        1.0,
        'missing-wallet',
      ],
    );
    await db.customStatement(
      'INSERT INTO scanner_templates '
      '(scanner_template_pk, date_created, template_name, contains, '
      'title_transaction_before, title_transaction_after, '
      'amount_transaction_before, amount_transaction_after, '
      'default_category_fk, wallet_fk, ignore) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'orphan-template',
        fixtureDate.millisecondsSinceEpoch ~/ 1000,
        'Template',
        'Merchant',
        '',
        '',
        '',
        '',
        'missing-category',
        'missing-wallet',
        0,
      ],
    );

    final audit = await auditDatabaseReferences(db);

    expect(audit.isValid, isFalse);
    expect(
      audit.violations.map((violation) => violation.relationship).toSet(),
      containsAll(<String>{
        'transactions.wallet',
        'transactions.category',
        'transactions.subcategory',
        'transactions.objective',
        'transactions.loanObjective',
        'transactions.pairedTransaction',
        'transactions.sharedBudget',
        'transactions.excludedBudgets',
        'categories.parent',
        'budgets.wallet',
        'budgets.wallets',
        'budgets.categories',
        'budgets.excludedCategories',
        'objectives.wallet',
        'categoryLimits.wallet',
        'categoryLimits.category',
        'categoryLimits.budget',
        'scannerTemplates.wallet',
        'scannerTemplates.category',
      }),
    );
  });
}
