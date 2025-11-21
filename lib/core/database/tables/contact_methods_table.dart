import 'table_schema.dart';

class ContactMethodsTable implements TableSchema {
  @override
  String get tableName => 'contact_methods';

  @override
  String get createTable => '''
    CREATE TABLE contact_methods (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      contact_type INTEGER NOT NULL,
      value TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id INTEGER NOT NULL,
      is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
    );
  ''';

  @override
  List<String> get indexes => [];
}
