import 'table_schema.dart';

class ExchangeRateDifferenceLinesTable implements TableSchema {
  @override
  String get tableName => 'exchange_rate_difference_lines';

  @override
  String get createTable => '''
    CREATE TABLE exchange_rate_difference_lines (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      proccess_number TEXT NOT NULL,
      type INTEGER NOT NULL,
      sub_type INTEGER NOT NULL,
      doc_id INTEGER NULL REFERENCES old_docs (id),
      doc_line_id INTEGER NULL REFERENCES old_doc_lines (id),
      account_id INTEGER NULL REFERENCES accounts (id),
      account_c_id INTEGER NOT NULL,
      u_no TEXT NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      currency_code TEXT NULL,
      debit_local_amount REAL NULL,
      credit_local_amount REAL NULL,
      exchange_rate REAL NULL,
      new_debit_local_amount REAL NULL,
      new_credit_local_amount REAL NULL,
      new_exchange_rate REAL NULL,
      difference_amount REAL NULL,
      difference_local_amount REAL NULL,
      difference_exchange_rate REAL NULL,
      exchange_rate_difference_id INTEGER NOT NULL REFERENCES exchange_rate_differences (id) ON DELETE CASCADE
    );
  ''';

  @override
  List<String> get indexes => [];
}
