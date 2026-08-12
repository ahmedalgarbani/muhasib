// data/datasources/sqflite_data_source.dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class SqfliteDataSource implements DatabaseService {
  final Database db;

  SqfliteDataSource(this.db);
  
  @override
  Future<void> addData({required String path, required Map<String, String> data, String? documentId}) async {
    final values = Map<String, Object?>.from(data);
    if (documentId != null) {
      values['id'] = int.tryParse(documentId) ?? documentId;
    }
    await db.insert(path, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Map<String, Object?>>> getData({required String path, String? documentId, Map<String, dynamic>? query}) {
    final filters = <String, Object?>{};
    if (query != null) {
      filters.addAll(query);
    }
    if (documentId != null) {
      filters['id'] = int.tryParse(documentId) ?? documentId;
    }
    final where = filters.isEmpty ? null : filters.keys.map((key) => '$key = ?').join(' AND ');
    return db.query(path, where: where, whereArgs: filters.values.toList());
  }
  // @override
  // Future<List<User>> getUsers() async {
  //   try {
  //     final result = await db.query('users');
  //     return result.map((e) => User(id: e['id'] as int, name: e['name'] as String)).toList();
  //   } catch (_) {
  //     throw LocalStorageException("Sqflite read failed");
  //   }
  // }

  // @override
  // Future<void> saveUser(User user) async {
  //   try {
  //     await db.insert('users', {'id': user.id, 'name': user.name});
  //   } catch (_) {
  //     throw LocalStorageException("Sqflite write failed");
  //   }
  // }
}
