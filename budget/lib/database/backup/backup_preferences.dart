import 'dart:convert';
import 'package:budget/pages/subscriptionsPage.dart'
    show SelectedSubscriptionsType;
import 'package:budget/widgets/notificationsSettings.dart'
    show ReminderNotificationType;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/widgets/periodCyclePicker.dart';

/// Validate present metadata without requiring optional historical settings.
/// Unknown JSON keys are retained; defaults/migrations still belong to startup.
Future<Map<String, dynamic>> decodeBackupPreferences(String source) async {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Backup preferences must be a JSON object.');
  }
  final defaults = await getDefaultPreferences();
  for (final entry in decoded.entries) {
    final value = entry.value;
    if (value == null) {
      continue; // Existing startup fills omitted/null defaults.
    }
    final expected = defaults[entry.key];
    bool valid = true;
    if (entry.key == 'animationSpeed') {
      final speed = num.tryParse(value.toString());
      valid = speed != null && speed.isFinite && speed > 0;
    } else if (entry.key == 'widgetOpacity') {
      valid = value is num && value.isFinite && value >= 0 && value <= 1;
    } else if (expected is bool) {
      valid = value is bool;
    } else if (expected is int) {
      valid = value is int;
    } else if (expected is num) {
      valid = value is num && value.isFinite;
    } else if (expected is String) {
      valid = value is String;
    } else if (expected is List) {
      valid = value is List;
    } else if (expected is Map) {
      valid = value is Map<String, dynamic>;
    }
    if (entry.key == 'selectedSubscriptionType') {
      valid = value is int &&
          value >= 0 &&
          value < SelectedSubscriptionsType.values.length;
    } else if (entry.key == 'notificationsReminderType') {
      valid = value is int &&
          value >= 0 &&
          value < ReminderNotificationType.values.length;
    } else if (entry.key == 'percentagePrecision') {
      valid = _isSupportedPercentagePrecision(value);
    } else if (['notificationHour', 'appOpenedHour'].contains(entry.key)) {
      valid = value is int && value >= 0 && value < TimeOfDay.hoursPerDay;
    } else if (['notificationMinute', 'appOpenedMinute'].contains(entry.key)) {
      valid = value is int && value >= 0 && value < TimeOfDay.minutesPerHour;
    } else if (entry.key.startsWith('selectedPeriodCycleType')) {
      valid = value is int && value >= 0 && value < CycleType.values.length;
    } else if (entry.key.startsWith('cycleReoccurrence')) {
      valid =
          value is int && value >= 0 && value < BudgetReoccurence.values.length;
    } else if (entry.key.startsWith('customPeriodEndDate') ||
        entry.key.startsWith('customPeriodStartDate') ||
        entry.key.startsWith('cycleStartDate') ||
        ['lastBackup', 'lineGraphStartDate', 'lastSynced']
            .contains(entry.key)) {
      valid = value is String &&
          (value.isEmpty || DateTime.tryParse(value) != null);
    } else if (entry.key == 'customCurrencies') {
      valid = value is List && value.every((v) => v is String);
    } else if (['customCurrencyAmounts', 'cachedCurrencyExchange']
        .contains(entry.key)) {
      valid = value is Map &&
          value.values.every((v) => v == null || (v is num && v.isFinite));
    } else if (entry.key == 'watchedCategoriesOnBudget') {
      valid = value is Map &&
          value.values.every((v) => v is List && v.every((id) => id is String));
    } else if (entry.key == 'usersNicknames') {
      valid = value is Map && value.values.every((v) => v is String);
    }
    if (['lastBackup', 'lineGraphStartDate', 'lastSynced']
        .contains(entry.key)) {
      valid = value is String && DateTime.tryParse(value) != null;
    }
    if ([
      'searchTransactionsSetFiltersString',
      'allSpendingSetFiltersString',
      'transactionsListPageSetFiltersString'
    ].contains(entry.key)) {
      valid = value is String;
    }
    if (!valid) {
      throw FormatException('Unsupported backup preference: ${entry.key}.');
    }
  }
  final theme = decoded['theme'];
  if (theme != null && !['system', 'light', 'dark', 'black'].contains(theme)) {
    throw const FormatException('Unsupported backup theme.');
  }
  for (final key in ['homePageOrder', 'homePageOrderFullScreen']) {
    final order = decoded[key];
    if (order is List && order.any((value) => value is! String)) {
      throw FormatException('Unsupported backup preference: $key.');
    }
  }
  return decoded;
}

// Match convertToPercent's formatter domain without narrowing compatible
// historical precision to the settings UI's 0/1/2 choices or coercing input.
bool _isSupportedPercentagePrecision(Object value) {
  if (value is! int) return false;
  try {
    0.0.toStringAsFixed(value);
    return true;
  } on RangeError {
    return false;
  }
}
