import 'table_schema.dart';

class OldDocsTable implements TableSchema {
  @override
  String get tableName => 'old_docs';

  @override
  String get createTable => '''
    CREATE TABLE old_docs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number INTEGER NOT NULL,
      type INTEGER NOT NULL,
      serial TEXT NOT NULL,
      reference_number TEXT NOT NULL,
      date INTEGER NOT NULL,
      description TEXT NOT NULL,
      u_no TEXT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      total_amount REAL NULL DEFAULT 0.0,
      total_local_amount REAL NULL DEFAULT 0.0
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_old_docs_date ON old_docs(date);',
  ];
}
