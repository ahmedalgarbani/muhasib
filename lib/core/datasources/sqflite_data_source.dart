// data/datasources/sqflite_data_source.dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class SqfliteDataSource implements DatabaseService {
  final Database db;

  SqfliteDataSource(this.db);
  
  @override
  Future<void> addData({required String path, required Map<String, String> data, String? documentId}) {
    // TODO: implement addData
    throw UnimplementedError();
  }
  
  @override
  Future getData({required String path, String? documentId, Map<String, dynamic>? query}) {
    // TODO: implement getData
    throw UnimplementedError();
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
