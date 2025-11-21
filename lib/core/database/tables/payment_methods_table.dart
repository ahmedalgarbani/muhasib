import 'table_schema.dart';

class PaymentMethodsTable implements TableSchema {
  @override
  String get tableName => 'payment_methods';

  @override
  String get createTable => '''
    CREATE TABLE payment_methods (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      amount REAL NOT NULL,
      currency_code TEXT NULL,
      exchange_rate REAL NULL,
      currency_id INTEGER NULL REFERENCES currencies (id),
      payment_method_type INTEGER NOT NULL,
      statement TEXT NULL,
      due_date INTEGER NULL,
      transfers_number TEXT NULL,
      check_number TEXT NULL,
      pay_for INTEGER NOT NULL,
      reference_number TEXT NULL,
      account_id INTEGER NULL REFERENCES accounts (id),
      bank_id INTEGER NULL REFERENCES banks (id),
      sender_name TEXT NULL,
      reciver_name TEXT NULL,
      transfer_commission_amount REAL NULL,
      transfer_commission_currency_code TEXT NULL,
      transfer_commission_exchange_rate REAL NULL,
      transfer_commission_currency_id INTEGER NULL REFERENCES currencies (id),
      customer_id INTEGER NULL REFERENCES customers (id),
      status INTEGER NOT NULL DEFAULT 0
    );
  ''';

  @override
  List<String> get indexes => [];
}
