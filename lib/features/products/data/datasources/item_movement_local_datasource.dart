import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/item_movement_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ItemMovementLocalDataSource {
  Future<List<ItemMovementModel>> getAllMovements();
  Future<List<ItemMovementModel>> getMovementsByProduct(int categoryId);
  Future<List<ItemMovementModel>> getMovementsByDateRange(int startDate, int endDate);
  Future<List<ItemMovementModel>> getMovementsByStock(int stockId);
  Future<List<ItemMovementModel>> getMovementsByType(int transDocType);
  Future<List<ItemMovementModel>> searchMovements(String query);
}

class ItemMovementLocalDataSourceImpl implements ItemMovementLocalDataSource {
  static const String _tableName = 'category_movs';
  final Database database;

  ItemMovementLocalDataSourceImpl({required this.database});

  @override
  Future<List<ItemMovementModel>> getAllMovements() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load movements: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemMovementModel>> getMovementsByProduct(int categoryId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load movements for product: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemMovementModel>> getMovementsByDateRange(int startDate, int endDate) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'trans_date >= ? AND trans_date <= ?',
        whereArgs: [startDate, endDate],
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load movements by date range: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemMovementModel>> getMovementsByStock(int stockId) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'stock_id = ?',
        whereArgs: [stockId],
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load movements by stock: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemMovementModel>> getMovementsByType(int transDocType) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'trans_doc_type = ?',
        whereArgs: [transDocType],
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load movements by type: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemMovementModel>> searchMovements(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'statement LIKE ? OR refrenc_no LIKE ? OR barcode_no LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'trans_date DESC, doc_no DESC',
      );
      return result.map((json) => ItemMovementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search movements: ${e.toString()}');
    }
  }
}
