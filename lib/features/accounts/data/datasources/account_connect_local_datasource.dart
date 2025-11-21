import 'package:hasib_lib/utils/app_logs.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account_connect_model.dart';

abstract class AccountConnectLocalDataSource {
  Future<List<AccountConnectModel>> getAllAccountConnects();
  Future<AccountConnectModel> getAccountConnectById(int id);
  Future<int> createAccountConnect(AccountConnectModel accountConnect);
  Future<void> updateAccountConnect(AccountConnectModel accountConnect);
  Future<void> deleteAccountConnect(int id);
  Future<AccountConnectModel?> getAccountConnectByType(int type);
}

class AccountConnectLocalDataSourceImpl
    implements AccountConnectLocalDataSource {
  final Database database;

  AccountConnectLocalDataSourceImpl({required this.database});

  @override
  Future<List<AccountConnectModel>> getAllAccountConnects() async {
    final List<Map<String, dynamic>> maps =
        await database.query('account_connects');
    return List.generate(maps.length, (i) {
      return AccountConnectModel.fromJson(maps[i]);
    });
  }

  @override
  Future<AccountConnectModel> getAccountConnectById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'account_connects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      throw Exception('AccountConnect not found');
    }

    return AccountConnectModel.fromJson(maps.first);
  }

  @override
  Future<int> createAccountConnect(AccountConnectModel accountConnect) async {
    final json = accountConnect.toJson();
    AppLogs.info('Creating account connect with data: $json');
    try {
      final id = await database.insert('account_connects', json);
      AppLogs.info('Account connect created with id: $id');
      return id;
    } catch (e) {
      AppLogs.error('Error creating account connect: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAccountConnect(AccountConnectModel accountConnect) async {
    await database.update(
      'account_connects',
      accountConnect.toJson(),
      where: 'id = ?',
      whereArgs: [accountConnect.id],
    );
  }

  @override
  Future<void> deleteAccountConnect(int id) async {
    await database.delete(
      'account_connects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<AccountConnectModel?> getAccountConnectByType(int type) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'account_connects',
      where: 'account_connect_type = ?',
      whereArgs: [type],
    );

    if (maps.isEmpty) {
      return null;
    }

    return AccountConnectModel.fromJson(maps.first);
  }
}
