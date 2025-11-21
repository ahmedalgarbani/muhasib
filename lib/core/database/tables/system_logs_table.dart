import 'table_schema.dart';

class SystemLogsTable implements TableSchema {
  @override
  String get tableName => 'system_logs';

  @override
  String get createTable => '''
    CREATE TABLE system_logs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      log_level TEXT NOT NULL,
      message TEXT NOT NULL,
      exception TEXT NULL,
      source TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
