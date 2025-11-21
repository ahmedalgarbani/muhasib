import 'table_schema.dart';

class AccountsTable implements TableSchema {
  @override
  String get tableName => 'accounts';

  @override
  String get createTable => '''
    CREATE TABLE accounts (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      c_id INTEGER NOT NULL UNIQUE,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      is_master INTEGER NOT NULL DEFAULT 0 CHECK (is_master IN (0, 1)),
      master_id INTEGER NULL,
      master_c_id INTEGER NULL,
      type INTEGER NOT NULL,
      national INTEGER NOT NULL,
      statement TEXT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      allow_update_delete INTEGER NOT NULL DEFAULT 1 CHECK (allow_update_delete IN (0, 1)),
      balance REAL NOT NULL DEFAULT 0.0,
      local_balance REAL NOT NULL DEFAULT 0.0,
      FOREIGN KEY (master_id) REFERENCES accounts (id)
    );
  ''';

  @override
  List<String> get indexes => [
        'CREATE INDEX idx_accounts_code ON accounts(code);',
        'CREATE INDEX idx_accounts_name ON accounts(name);',
        'CREATE INDEX idx_accounts_c_id ON accounts(c_id);',
        'CREATE INDEX idx_accounts_type ON accounts(type);',
        'CREATE INDEX idx_accounts_master_id ON accounts(master_id);',
        'CREATE INDEX idx_accounts_is_master ON accounts(is_master);',
      ];
}

