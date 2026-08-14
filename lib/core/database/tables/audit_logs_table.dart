import 'table_schema.dart';

class AuditLogsTable implements TableSchema {
  @override
  String get tableName => 'audit_logs';

  @override
  String get createTable => '''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NULL DEFAULT 1,
      action_type TEXT NULL,
      action TEXT NULL,
      table_name TEXT NULL,
      entity_type TEXT NULL,
      record_id INTEGER NULL,
      entity_id INTEGER NULL,
      old_values TEXT NULL,
      new_values TEXT NULL,
      ip_address TEXT NULL,
      user_agent TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      created_at INTEGER NULL,
      description TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_time ON audit_logs(creation_time);',
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);',
  ];
}
