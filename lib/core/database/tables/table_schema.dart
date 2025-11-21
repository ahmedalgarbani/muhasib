abstract class TableSchema {
  String get createTable;
  String get tableName;
  List<String> get indexes => [];
}
