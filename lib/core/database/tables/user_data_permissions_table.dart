import 'table_schema.dart';

class UserDataPermissionsTable implements TableSchema {
  @override
  String get tableName => 'user_data_permissions';

  @override
  String get createTable => '''
    CREATE TABLE user_data_permissions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      user_id INTEGER NOT NULL REFERENCES app_users (id) ON DELETE CASCADE,
      resource_type INTEGER NOT NULL,
      resource_id TEXT NOT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
