/// Contract for database table definitions and schema DDL.
abstract class TableSchema {
  /// SQL statement to create the table
  String get createTable;

  /// Name of the SQLite table
  String get tableName;

  /// Optional list of index creation SQL statements
  List<String> get indexes => const [];
}

/// Extension methods for [TableSchema]
extension TableSchemaX on TableSchema {
  /// Standard SQL statement to drop the table safely
  String get dropTable => 'DROP TABLE IF EXISTS $tableName;';
}


