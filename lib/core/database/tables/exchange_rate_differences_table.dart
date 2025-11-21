import 'table_schema.dart';

class ExchangeRateDifferencesTable implements TableSchema {
  @override
  String get tableName => 'exchange_rate_differences';

  @override
  String get createTable => '''
    CREATE TABLE exchange_rate_differences (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number INTEGER NOT NULL,
      from_doc_id INTEGER NOT NULL,
      to_doc_id INTEGER NOT NULL,
      from_date INTEGER NOT NULL,
      to_date INTEGER NOT NULL,
      date INTEGER NOT NULL,
      u_no TEXT NULL,
      status INTEGER NOT NULL DEFAULT 0
    );
  ''';

  @override
  List<String> get indexes => [];
}
