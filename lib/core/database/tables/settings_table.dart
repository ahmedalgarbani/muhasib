import 'table_schema.dart';

class SettingsTable implements TableSchema {
  @override
  String get tableName => 'settings';

  @override
  String get createTable => '''
    CREATE TABLE settings (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      setting_key TEXT NOT NULL UNIQUE,
      setting_value TEXT NOT NULL,
      setting_type TEXT NOT NULL DEFAULT 'STRING',
      description TEXT NULL,
      category TEXT NOT NULL DEFAULT 'General'
    );
  ''';

  @override
  List<String> get indexes => [];
}
