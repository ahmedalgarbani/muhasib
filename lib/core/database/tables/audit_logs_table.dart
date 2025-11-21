import 'table_schema.dart';

class AuditLogsTable implements TableSchema {
  @override
  String get tableName => 'audit_logs';

  @override
  String get createTable => '''
    CREATE TABLE audit_logs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NULL REFERENCES app_users (id),
      action_type TEXT NOT NULL,
      table_name TEXT NOT NULL,
      record_id INTEGER NOT NULL,
      old_values TEXT NULL,
      new_values TEXT NULL,
      ip_address TEXT NULL,
      user_agent TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      description TEXT NULL
    );
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_audit_logs_time ON audit_logs(creation_time);',
    'CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);',
  ];
}
