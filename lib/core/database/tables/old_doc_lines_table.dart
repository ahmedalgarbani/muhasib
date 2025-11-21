import 'table_schema.dart';

class OldDocLinesTable implements TableSchema {
  @override
  String get tableName => 'old_doc_lines';

  @override
  String get createTable => '''
    CREATE TABLE old_doc_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      number TEXT NOT NULL,
      type INTEGER NOT NULL,
      sub_type INTEGER NOT NULL,
      serial TEXT NOT NULL,
      reference_number TEXT NOT NULL,
      date INTEGER NOT NULL,
      description TEXT NOT NULL,
      statement TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      account_c_id INTEGER NOT NULL,
      pay_type INTEGER NOT NULL,
      amount REAL NULL,
      local_amount REAL NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      account_amount REAL NULL,
      account_local_amount REAL NULL,
      account_limit_code TEXT NULL,
      account_exchange_rate REAL NULL,
      account_limit_id INTEGER NULL REFERENCES currencies (id),
      credit_amount REAL NULL,
      credit_local_amount REAL NULL,
      credit_currency_code TEXT NULL,
      credit_exchange_rate REAL NULL,
      credit_currency_id INTEGER NULL REFERENCES currencies (id),
      debit_amount REAL NULL,
      debit_local_amount REAL NULL,
      debit_currency_code TEXT NULL,
      debit_exchange_rate REAL NULL,
      debit_currency_id INTEGER NULL REFERENCES currencies (id),
      doc_id INTEGER NULL REFERENCES old_docs (id) ON DELETE CASCADE,
      account_id INTEGER NULL REFERENCES accounts (id),
      u_no TEXT NULL,
      "order" INTEGER NOT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_old_doc_lines_doc ON old_doc_lines(doc_id);',
  ];
}
