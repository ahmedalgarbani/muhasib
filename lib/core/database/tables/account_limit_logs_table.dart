import 'table_schema.dart';

class AccountLimitLogsTable implements TableSchema {
  @override
  String get tableName => 'account_limit_logs';

  @override
  String get createTable => '''
    CREATE TABLE account_limit_logs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL REFERENCES accounts (id),
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      debit_amount REAL NOT NULL DEFAULT 0.0,
      credit_amount REAL NOT NULL DEFAULT 0.0,
      transaction_date INTEGER NOT NULL,
      transaction_type TEXT NULL,
      transaction_id INTEGER NULL,
      description TEXT NULL,
      created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_account_limit_logs_account ON account_limit_logs(account_id);',
    'CREATE INDEX idx_account_limit_logs_date ON account_limit_logs(transaction_date);',
  ];
}
