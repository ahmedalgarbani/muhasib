import 'table_schema.dart';

class UserPermissionsTable implements TableSchema {
  @override
  String get tableName => 'user_permissions';

  @override
  String get createTable => '''
    CREATE TABLE user_permissions (
      creator_id INTEGER NULL DEFAULT 1,
      last_modifier_id INTEGER NULL DEFAULT 1,
      concurrency_stamp TEXT NULL,
      extra_properties TEXT NULL,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(creation_time > 946674000),
      last_modification_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)) CHECK(last_modification_time > 946674000),
      user_id INTEGER NOT NULL REFERENCES app_users (id) ON DELETE CASCADE,
      feature_id INTEGER NOT NULL,
      can_view INTEGER NOT NULL DEFAULT 0 CHECK (can_view IN (0, 1)),
      can_add INTEGER NOT NULL DEFAULT 0 CHECK (can_add IN (0, 1)),
      can_edit INTEGER NOT NULL DEFAULT 0 CHECK (can_edit IN (0, 1)),
      can_delete INTEGER NOT NULL DEFAULT 0 CHECK (can_delete IN (0, 1)),
      can_export INTEGER NOT NULL DEFAULT 0 CHECK (can_export IN (0, 1)),
      PRIMARY KEY (user_id, feature_id)
    );
  ''';

  @override
  List<String> get indexes => [];
}
