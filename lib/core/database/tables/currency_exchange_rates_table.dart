import 'table_schema.dart';

/// Table to track historical exchange rates with effective dates
class CurrencyExchangeRatesTable implements TableSchema {
  @override
  String get tableName => 'currency_exchange_rates';

  @override
  String get createTable => '''
    CREATE TABLE currency_exchange_rates (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      currency_id INTEGER NOT NULL REFERENCES currencies (id),
      exchange_rate REAL NOT NULL,
      effective_date INTEGER NOT NULL,
      end_date INTEGER NULL,
      notes TEXT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_currency_exchange_rates_currency_id ON currency_exchange_rates (currency_id)',
    'CREATE INDEX idx_currency_exchange_rates_effective_date ON currency_exchange_rates (effective_date)',
  ];
}
