import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';

class DatabaseReferenceViolation {
  final String relationship;
  final String sourceTable;
  final String targetTable;
  final List<String> sourceKeys;
  final String detail;

  const DatabaseReferenceViolation({
    required this.relationship,
    required this.sourceTable,
    required this.targetTable,
    required this.sourceKeys,
    required this.detail,
  });
}

class DatabaseReferenceAudit {
  final List<DatabaseReferenceViolation> violations;

  const DatabaseReferenceAudit(this.violations);

  bool get isValid => violations.isEmpty;

  int get totalViolations => violations.fold<int>(
        0,
        (total, violation) => total + violation.sourceKeys.length,
      );
}

Future<DatabaseReferenceAudit> auditDatabaseReferences(
  FinanceDatabase database,
) async {
  final violations = <DatabaseReferenceViolation>[];

  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.wallet',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'wallet_fk',
    targetTable: 'wallets',
    targetKey: 'wallet_pk',
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.category',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'category_fk',
    targetTable: 'categories',
    targetKey: 'category_pk',
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.subcategory',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'sub_category_fk',
    targetTable: 'categories',
    targetKey: 'category_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.objective',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'objective_fk',
    targetTable: 'objectives',
    targetKey: 'objective_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.loanObjective',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'objective_loan_fk',
    targetTable: 'objectives',
    targetKey: 'objective_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.pairedTransaction',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'paired_transaction_fk',
    targetTable: 'transactions',
    targetKey: 'transaction_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'transactions.sharedBudget',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'shared_reference_budget_pk',
    targetTable: 'budgets',
    targetKey: 'budget_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'categories.parent',
    sourceTable: 'categories',
    sourceKey: 'category_pk',
    sourceColumn: 'main_category_pk',
    targetTable: 'categories',
    targetKey: 'category_pk',
    nullable: true,
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'budgets.wallet',
    sourceTable: 'budgets',
    sourceKey: 'budget_pk',
    sourceColumn: 'wallet_fk',
    targetTable: 'wallets',
    targetKey: 'wallet_pk',
  );
  await _auditDirectReference(
    database,
    violations,
    relationship: 'objectives.wallet',
    sourceTable: 'objectives',
    sourceKey: 'objective_pk',
    sourceColumn: 'wallet_fk',
    targetTable: 'wallets',
    targetKey: 'wallet_pk',
  );

  for (final relation in const <_DirectRelation>[
    _DirectRelation(
      'categoryLimits.wallet',
      'category_budget_limits',
      'category_limit_pk',
      'wallet_fk',
      'wallets',
      'wallet_pk',
    ),
    _DirectRelation(
      'categoryLimits.category',
      'category_budget_limits',
      'category_limit_pk',
      'category_fk',
      'categories',
      'category_pk',
    ),
    _DirectRelation(
      'categoryLimits.budget',
      'category_budget_limits',
      'category_limit_pk',
      'budget_fk',
      'budgets',
      'budget_pk',
    ),
    _DirectRelation(
      'scannerTemplates.wallet',
      'scanner_templates',
      'scanner_template_pk',
      'wallet_fk',
      'wallets',
      'wallet_pk',
    ),
    _DirectRelation(
      'scannerTemplates.category',
      'scanner_templates',
      'scanner_template_pk',
      'default_category_fk',
      'categories',
      'category_pk',
    ),
  ]) {
    await _auditDirectReference(
      database,
      violations,
      relationship: relation.relationship,
      sourceTable: relation.sourceTable,
      sourceKey: relation.sourceKey,
      sourceColumn: relation.sourceColumn,
      targetTable: relation.targetTable,
      targetKey: relation.targetKey,
    );
  }

  await _auditSerializedReference(
    database,
    violations,
    relationship: 'transactions.excludedBudgets',
    sourceTable: 'transactions',
    sourceKey: 'transaction_pk',
    sourceColumn: 'budget_fks_exclude',
    targetTable: 'budgets',
    targetKey: 'budget_pk',
  );
  await _auditSerializedReference(
    database,
    violations,
    relationship: 'budgets.wallets',
    sourceTable: 'budgets',
    sourceKey: 'budget_pk',
    sourceColumn: 'wallet_fks',
    targetTable: 'wallets',
    targetKey: 'wallet_pk',
  );
  await _auditSerializedReference(
    database,
    violations,
    relationship: 'budgets.categories',
    sourceTable: 'budgets',
    sourceKey: 'budget_pk',
    sourceColumn: 'category_fks',
    targetTable: 'categories',
    targetKey: 'category_pk',
  );
  await _auditSerializedReference(
    database,
    violations,
    relationship: 'budgets.excludedCategories',
    sourceTable: 'budgets',
    sourceKey: 'budget_pk',
    sourceColumn: 'category_fks_exclude',
    targetTable: 'categories',
    targetKey: 'category_pk',
  );

  return DatabaseReferenceAudit(List.unmodifiable(violations));
}

Future<void> _auditDirectReference(
  FinanceDatabase database,
  List<DatabaseReferenceViolation> violations, {
  required String relationship,
  required String sourceTable,
  required String sourceKey,
  required String sourceColumn,
  required String targetTable,
  required String targetKey,
  bool nullable = false,
}) async {
  final rows = await database.customSelect(
    'SELECT source."$sourceKey" AS source_key '
    'FROM "$sourceTable" source '
    'LEFT JOIN "$targetTable" target '
    'ON source."$sourceColumn" = target."$targetKey" '
    'WHERE ${nullable ? 'source."$sourceColumn" IS NOT NULL AND ' : ''}'
    'target."$targetKey" IS NULL',
  ).get();
  if (rows.isEmpty) return;

  violations.add(DatabaseReferenceViolation(
    relationship: relationship,
    sourceTable: sourceTable,
    targetTable: targetTable,
    sourceKeys: rows
        .map((row) => row.data['source_key'].toString())
        .toList(growable: false),
    detail: '$sourceColumn does not resolve to $targetTable.$targetKey.',
  ));
}

Future<void> _auditSerializedReference(
  FinanceDatabase database,
  List<DatabaseReferenceViolation> violations, {
  required String relationship,
  required String sourceTable,
  required String sourceKey,
  required String sourceColumn,
  required String targetTable,
  required String targetKey,
}) async {
  final targetRows = await database.customSelect(
    'SELECT "$targetKey" AS target_key FROM "$targetTable"',
  ).get();
  final targetKeys = targetRows
      .map((row) => row.data['target_key'].toString())
      .toSet();
  final sourceRows = await database.customSelect(
    'SELECT "$sourceKey" AS source_key, "$sourceColumn" AS encoded_keys '
    'FROM "$sourceTable" WHERE "$sourceColumn" IS NOT NULL',
  ).get();
  final invalidSourceKeys = <String>[];

  for (final row in sourceRows) {
    final source = row.data['source_key'].toString();
    final encoded = row.data['encoded_keys'];
    try {
      final decoded = json.decode(encoded as String);
      if (decoded is! List ||
          decoded.any((entry) => !targetKeys.contains(entry.toString()))) {
        invalidSourceKeys.add(source);
      }
    } catch (_) {
      invalidSourceKeys.add(source);
    }
  }
  if (invalidSourceKeys.isEmpty) return;

  violations.add(DatabaseReferenceViolation(
    relationship: relationship,
    sourceTable: sourceTable,
    targetTable: targetTable,
    sourceKeys: List.unmodifiable(invalidSourceKeys),
    detail: '$sourceColumn contains malformed or unresolved identifiers.',
  ));
}

class _DirectRelation {
  final String relationship;
  final String sourceTable;
  final String sourceKey;
  final String sourceColumn;
  final String targetTable;
  final String targetKey;

  const _DirectRelation(
    this.relationship,
    this.sourceTable,
    this.sourceKey,
    this.sourceColumn,
    this.targetTable,
    this.targetKey,
  );
}
