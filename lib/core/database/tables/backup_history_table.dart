import 'table_schema.dart';

class BackupHistoryTable implements TableSchema {
  @override
  String get tableName => 'backup_history';

  @override
  String get createTable => '''
    CREATE TABLE backup_history (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      file_name TEXT NOT NULL,
      file_size INTEGER NOT NULL,
      backup_type TEXT NOT NULL,
      status TEXT NOT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      completed_time INTEGER NULL
    );
  ''';

  @override
  List<String> get indexes => [];
}
