import 'table_schema.dart';

class SystemSequencesTable implements TableSchema {
  @override
  String get tableName => 'system_sequences';

  @override
  String get createTable => '''
    CREATE TABLE system_sequences (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      sequence_type TEXT NOT NULL UNIQUE,
      last_number INTEGER NOT NULL DEFAULT 0,
      prefix TEXT NULL,
      suffix TEXT NULL,
      padding INTEGER NULL DEFAULT 0,
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
