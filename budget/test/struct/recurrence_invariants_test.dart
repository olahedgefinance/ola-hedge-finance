import 'package:budget/database/tables.dart';
import 'package:budget/struct/upcomingTransactionsFunctions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('predictable recurrence keys advance without creating a new branch', () {
    final first = updatePredictableKey('transaction-root');
    final second = updatePredictableKey(first);
    final third = updatePredictableKey(second);

    expect(first, 'transaction-root::predict::1');
    expect(second, 'transaction-root::predict::2');
    expect(third, 'transaction-root::predict::3');
  });

  test('daily recurrence count includes both boundary dates', () {
    expect(
      countTransactionOccurrences(
        type: TransactionSpecialType.repetitive,
        reoccurrence: BudgetReoccurence.daily,
        periodLength: 1,
        dateCreated: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
      ),
      5,
    );
  });

  test('weekly recurrence count advances in seven-day periods', () {
    expect(
      countTransactionOccurrences(
        type: TransactionSpecialType.subscription,
        reoccurrence: BudgetReoccurence.weekly,
        periodLength: 1,
        dateCreated: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 29),
      ),
      5,
    );
  });

  test('monthly and yearly recurrence counts preserve calendar cadence', () {
    expect(
      countTransactionOccurrences(
        type: TransactionSpecialType.repetitive,
        reoccurrence: BudgetReoccurence.monthly,
        periodLength: 1,
        dateCreated: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 4, 15),
      ),
      4,
    );
    expect(
      countTransactionOccurrences(
        type: TransactionSpecialType.repetitive,
        reoccurrence: BudgetReoccurence.yearly,
        periodLength: 1,
        dateCreated: DateTime(2020, 1, 15),
        endDate: DateTime(2024, 1, 15),
      ),
      5,
    );
  });

  test('non-recurring and excessive schedules do not produce unsafe counts',
      () {
    expect(
      countTransactionOccurrences(
        type: null,
        reoccurrence: BudgetReoccurence.daily,
        periodLength: 1,
        dateCreated: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      ),
      isNull,
    );
    expect(
      countTransactionOccurrences(
        type: TransactionSpecialType.repetitive,
        reoccurrence: BudgetReoccurence.daily,
        periodLength: 1,
        dateCreated: DateTime(2020, 1, 1),
        endDate: DateTime(2024, 1, 1),
      ),
      isNull,
    );
  });
}
