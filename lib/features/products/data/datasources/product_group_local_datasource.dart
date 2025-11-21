import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/products/data/models/product_group_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ProductGroupLocalDataSource {
  Future<List<ProductGroupModel>> getAllGroups();
  Future<ProductGroupModel> getGroupById(int id);
  Future<int> insertGroup(ProductGroupModel group);
  Future<void> updateGroup(ProductGroupModel group);
  Future<void> deleteGroup(int id);
  Future<List<ProductGroupModel>> searchGroups(String query);
  Future<List<ProductGroupModel>> getGroupsByParent(int? parentId);
}

class ProductGroupLocalDataSourceImpl implements ProductGroupLocalDataSource {
  static const String _tableName = 'categories_groups';
  final Database database;

  ProductGroupLocalDataSourceImpl({required this.database});

  @override
  Future<List<ProductGroupModel>> getAllGroups() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductGroupModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load product groups: ${e.toString()}');
    }
  }

  @override
  Future<ProductGroupModel> getGroupById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        throw LocalStorageException('Product group with id $id not found');
      }
      
      return ProductGroupModel.fromJson(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get product group: ${e.toString()}');
    }
  }

  @override
  Future<int> insertGroup(ProductGroupModel group) async {
    try {
      final data = group.toJson();
      // Ensure timestamps are set (redundant safety check)
      data['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
      data['last_modification_time'] ??= DateTime.now().millisecondsSinceEpoch;
      
      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert product group: ${e.toString()}');
    }
  }

  @override
  Future<void> updateGroup(ProductGroupModel group) async {
    if (group.id == null) {
      throw LocalStorageException('Product group id is required for update');
    }
    
    try {
      final count = await database.update(
        _tableName,
        group.toJson(),
        where: 'id = ?',
        whereArgs: [group.id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product group with id ${group.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update product group: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteGroup(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw LocalStorageException('Product group with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete product group: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductGroupModel>> searchGroups(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductGroupModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search product groups: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductGroupModel>> getGroupsByParent(int? parentId) async {
    try {
      final result = await database.query(
        _tableName,
        where: parentId == null ? 'parent_group_id IS NULL' : 'parent_group_id = ?',
        whereArgs: parentId == null ? null : [parentId],
        orderBy: 'name ASC',
      );
      return result.map((json) => ProductGroupModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get groups by parent: ${e.toString()}');
    }
  }
}
