import 'table_schema.dart';

class AppUsersTable implements TableSchema {
  @override
  String get tableName => 'app_users';

  @override
  String get createTable => '''
    CREATE TABLE app_users (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      name TEXT NOT NULL,
      email TEXT NULL UNIQUE,
      dial_code TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      device_id TEXT NOT NULL,
      password TEXT NOT NULL,
      role INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      last_login INTEGER NULL,
      profile_image TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
