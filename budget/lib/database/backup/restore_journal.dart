import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Internal recovery evidence, never part of the exported SQLite format.
/// A pending operation is rolled back before any database executor can open.
class RestoreJournal {
  RestoreJournal(this.liveDatabase, this.preferences);
  final File liveDatabase;
  final SharedPreferences preferences;
  File get file => File('${liveDatabase.path}.restore-pending.json');
  File get preimage => File('${liveDatabase.path}.restore-preimage.sqlite');

  Future<void> prepare(Map<String, String?> previous) async {
    if (await file.exists()) throw StateError('Restore recovery is pending.');
    final existed = await liveDatabase.exists();
    if (existed) {
      await preimage.writeAsBytes(await liveDatabase.readAsBytes(),
          flush: true);
    }
    final staged = File('${file.path}.stage');
    await staged.writeAsString(
        jsonEncode({
          'version': 1,
          'hadDatabase': existed,
          'preferences': previous,
        }),
        flush: true);
    await staged.rename(file.path);
  }

  /// Removing the pending marker is the commit point. Before then startup
  /// always restores the preimage, including interruption during compensation.
  Future<void> commit() async {
    await file.delete();
  }

  Future<void> recover() async {
    if (!await file.exists()) return;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['hadDatabase'] is! bool ||
        decoded['preferences'] is! Map) {
      throw const FormatException('Restore recovery evidence is invalid.');
    }
    final previous = decoded['preferences'] as Map;
    for (final key in ['userSettings', 'dateOfLastSyncedWithClient']) {
      if (!previous.containsKey(key) ||
          (previous[key] != null && previous[key] is! String)) {
        throw const FormatException(
            'Restore recovery preferences are invalid.');
      }
    }
    // The preimage is copied, never consumed. A failed retry remains recoverable.
    if (decoded['hadDatabase'] == true) {
      final bytes = await preimage.readAsBytes();
      if (bytes.length < 512 ||
          utf8.decode(bytes.take(15).toList(), allowMalformed: true) !=
              'SQLite format 3') {
        throw const FormatException('Restore recovery database is invalid.');
      }
      await liveDatabase.writeAsBytes(bytes, flush: true);
    } else if (await liveDatabase.exists()) {
      await liveDatabase.delete();
    }
    for (final key in ['userSettings', 'dateOfLastSyncedWithClient']) {
      final value = previous[key] as String?;
      final saved = value == null
          ? await preferences.remove(key)
          : await preferences.setString(key, value);
      if (!saved) {
        throw StateError('Restore recovery could not save preferences.');
      }
    }
    await commit();
  }
}
