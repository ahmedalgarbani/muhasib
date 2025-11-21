import 'table_schema.dart';

class LoyaltyProgramsTable implements TableSchema {
  @override
  String get tableName => 'loyalty_programs';

  @override
  String get createTable => '''
    CREATE TABLE loyalty_programs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      name TEXT NOT NULL,
      points_per_amount REAL NOT NULL,
      redemption_ratio REAL NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      min_redemption_points REAL NULL,
      description TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
