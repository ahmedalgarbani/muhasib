import 'table_schema.dart';

class CategoriesGroupsTable implements TableSchema {
  @override
  String get tableName => 'categories_groups';

  @override
  String get createTable => '''
    CREATE TABLE categories_groups (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      description TEXT NULL,
      parent_group_id INTEGER NULL REFERENCES categories_groups (id)
    );
  ''';

  @override
  List<String> get indexes => [];
}
