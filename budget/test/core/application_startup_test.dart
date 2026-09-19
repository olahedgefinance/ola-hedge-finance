import 'package:flutter_test/flutter_test.dart';

import '../support/finance_database_fixture.dart';

void main() {
  test('core local database initializes at the current healthy schema',
      () async {
    final db = await createTestDatabase();
    addTearDown(db.close);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(await databaseUserVersion(db), 46);
    expect(tables, hasLength(10));
    expect(await databaseIntegrity(db), 'ok');
    expect(await foreignKeyViolations(db), isEmpty);
  });
}
