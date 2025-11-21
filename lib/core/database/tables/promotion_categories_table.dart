import 'table_schema.dart';

class PromotionCategoriesTable implements TableSchema {
  @override
  String get tableName => 'promotion_categories';

  @override
  String get createTable => '''
    CREATE TABLE promotion_categories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      promotion_id INTEGER NOT NULL REFERENCES promotions (id) ON DELETE CASCADE,
      category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
      creation_time INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
      UNIQUE(promotion_id, category_id)
    );
  ''';

  @override
  List<String> get indexes => [];
}
