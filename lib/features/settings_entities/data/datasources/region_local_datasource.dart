import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/settings_entities/data/models/region_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class RegionLocalDataSource {
  Future<List<RegionModel>> getRegions();
  Future<RegionModel> getRegionById(int id);
  Future<List<RegionModel>> getActiveRegions();
  Future<int> insertRegion(RegionModel region);
  Future<void> updateRegion(RegionModel region);
  Future<void> deleteRegion(int id);
  Future<List<RegionModel>> searchRegions(String query);
}

class RegionLocalDataSourceImpl implements RegionLocalDataSource {
  static const String _tableName = 'regions';
  final Database database;

  RegionLocalDataSourceImpl({required this.database});

  @override
  Future<List<RegionModel>> getRegions() async {
    try {
      final result = await database.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return result.map((json) => RegionModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load regions: ${e.toString()}');
    }
  }

  @override
  Future<RegionModel> getRegionById(int id) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw LocalStorageException('Region with id $id not found');
      }

      return RegionModel.fromMap(result.first);
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to get region: ${e.toString()}');
    }
  }

  @override
  Future<List<RegionModel>> getActiveRegions() async {
    try {
      final result = await database.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => RegionModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to load active regions: ${e.toString()}');
    }
  }

  @override
  Future<int> insertRegion(RegionModel region) async {
    try {
      final data = region.toMap();
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;

      return await database.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw LocalStorageException('Failed to insert region: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRegion(RegionModel region) async {
    if (region.id == null) {
      throw LocalStorageException('Region id is required for update');
    }

    try {
      final data = region.toMap();
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final count = await database.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [region.id],
      );

      if (count == 0) {
        throw LocalStorageException('Region with id ${region.id} not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to update region: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteRegion(int id) async {
    try {
      final count = await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw LocalStorageException('Region with id $id not found');
      }
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to delete region: ${e.toString()}');
    }
  }

  @override
  Future<List<RegionModel>> searchRegions(String query) async {
    try {
      final result = await database.query(
        _tableName,
        where: 'name LIKE ? OR country LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((json) => RegionModel.fromMap(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to search regions: ${e.toString()}');
    }
  }
}

