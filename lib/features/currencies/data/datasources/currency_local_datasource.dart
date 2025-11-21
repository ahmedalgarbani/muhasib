import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:sqflite/sqflite.dart';
import '../models/currency_model.dart';

abstract class CurrencyLocalDataSource {
  Future<List<CurrencyModel>> getAllCurrencies();
  Future<CurrencyModel> getCurrencyById(int id);
  Future<CurrencyModel> getCurrencyByCode(String code);
  Future<int> insertCurrency(CurrencyModel currency);
  Future<int> updateCurrency(CurrencyModel currency);
  Future<int> deleteCurrency(int id);
  Future<List<CurrencyModel>> searchCurrencies(String query);
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  final Database database;
  final String tableName = CurrenciesTable().tableName;

  CurrencyLocalDataSourceImpl(this.database);

  @override
  Future<List<CurrencyModel>> getAllCurrencies() async {
    try {
      final maps = await database.query(tableName, orderBy: 'code ASC');
      return maps.map((e) => CurrencyModel.fromJson(e)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to get all currencies: ${e.toString()}',
      );
    }
  }

  @override
  Future<CurrencyModel> getCurrencyById(int id) async {
    try {
      final maps = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) {
        throw LocalStorageException('Currency with id $id not found');
      }
      return CurrencyModel.fromJson(maps.first);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get currency by id: ${e.toString()}',
      );
    }
  }

  @override
  Future<CurrencyModel> getCurrencyByCode(String code) async {
    try {
      final maps = await database.query(
        tableName,
        where: 'code = ?',
        whereArgs: [code],
      );
      if (maps.isEmpty) {
        throw LocalStorageException('Currency with code $code not found');
      }
      return CurrencyModel.fromJson(maps.first);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get currency by code: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> insertCurrency(CurrencyModel currency) async {
    try {
      final data = currency.toJson();
      // Ensure timestamps are set (in seconds, not milliseconds)
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['creation_time'] ??= nowInSeconds;
      data['last_modification_time'] ??= nowInSeconds;
      
      final id = await database.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id;
    } catch (e) {
      throw LocalStorageException('Failed to insert currency: ${e.toString()}');
    }
  }

  @override
  Future<int> updateCurrency(CurrencyModel currency) async {
    try {
      final data = currency.toJson();
      // Update the last modification time (in seconds)
      data['last_modification_time'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final count = await database.update(
        tableName,
        data,
        where: 'id = ?',
        whereArgs: [currency.id],
      );
      if (count == 0) {
        throw LocalStorageException(
          'Currency with id ${currency.id} not found',
        );
      }
      return count;
    } catch (e) {
      throw LocalStorageException('Failed to update currency: ${e.toString()}');
    }
  }

  @override
  Future<int> deleteCurrency(int id) async {
    try {
      final count = await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw LocalStorageException('Currency with id $id not found');
      }
      return count;
    } catch (e) {
      throw LocalStorageException('Failed to delete currency: ${e.toString()}');
    }
  }

  @override
  Future<List<CurrencyModel>> searchCurrencies(String query) async {
    try {
      final maps = await database.query(
        tableName,
        where: 'name LIKE ? OR code LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'code ASC',
      );
      return maps.map((e) => CurrencyModel.fromJson(e)).toList();
    } catch (e) {
      throw LocalStorageException(
        'Failed to search currencies: ${e.toString()}',
      );
    }
  }
}
