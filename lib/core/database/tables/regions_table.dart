import 'table_schema.dart';

class RegionsTable implements TableSchema {
  @override
  String get tableName => 'regions';

  @override
  String get createTable => '''
    CREATE TABLE regions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      code TEXT NULL,
      country TEXT NULL DEFAULT 'اليمن',
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      parent_region_id INTEGER NULL REFERENCES regions (id),
      description TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_regions_name ON regions(name);',
    'CREATE INDEX IF NOT EXISTS idx_regions_parent ON regions(parent_region_id);',
    'CREATE INDEX IF NOT EXISTS idx_regions_code ON regions(code);',
  ];
}
