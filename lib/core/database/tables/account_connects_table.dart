import 'table_schema.dart';

class AccountConnectsTable implements TableSchema {
  @override
  String get tableName => 'account_connects';

  @override
  String get createTable => '''
    CREATE TABLE account_connects (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      account_connect_type INTEGER NOT NULL,
      c_id INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX idx_account_connects_type ON account_connects(account_connect_type);',
        'CREATE INDEX idx_account_connects_c_id ON account_connects(c_id);',
      ];
}
