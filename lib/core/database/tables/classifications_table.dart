import 'table_schema.dart';

class ClassificationsTable implements TableSchema {
  @override
  String get tableName => 'classifications';

  @override
  String get createTable => '''
    CREATE TABLE classifications (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      singler_name TEXT NOT NULL,
      "order" INTEGER NOT NULL,
      description TEXT NULL,
      icon TEXT NULL,
      type INTEGER NOT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
