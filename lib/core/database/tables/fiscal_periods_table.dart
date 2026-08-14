import 'table_schema.dart';

class FiscalPeriodsTable implements TableSchema {
  @override
  String get tableName => 'fiscal_periods';

  @override
  String get createTable => '''
    CREATE TABLE IF NOT EXISTS fiscal_periods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year INTEGER NOT NULL,
      period INTEGER NOT NULL,
      start_date INTEGER NOT NULL,
      end_date INTEGER NOT NULL,
      status INTEGER DEFAULT 0,
      is_closed INTEGER DEFAULT 0,
      closed_by INTEGER,
      closed_at INTEGER,
      notes TEXT,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      UNIQUE(year, period)
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_fiscal_periods_year ON fiscal_periods(year);',
    'CREATE INDEX IF NOT EXISTS idx_fiscal_periods_status ON fiscal_periods(status);',
    'CREATE INDEX IF NOT EXISTS idx_fiscal_periods_dates ON fiscal_periods(start_date, end_date);',
  ];
}
