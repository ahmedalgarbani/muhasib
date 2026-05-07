import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import '../models/fiscal_period_model.dart';

abstract class FiscalPeriodDataSource {
  Future<List<FiscalPeriodModel>> getAllPeriods();
  Future<FiscalPeriodModel?> getPeriodForDate(DateTime date);
  Future<FiscalPeriodModel?> getPeriod(int year, int period);
  Future<int> createPeriod(FiscalPeriodModel period);
  Future<void> closePeriod(int periodId, int userId);
  Future<void> reopenPeriod(int periodId);
  Future<void> lockPeriod(int periodId);
}

class FiscalPeriodDataSourceImpl implements FiscalPeriodDataSource {
  final Database database;

  FiscalPeriodDataSourceImpl({required this.database});

  @override
  Future<List<FiscalPeriodModel>> getAllPeriods() async {
    try {
      final results = await database.query(
        'fiscal_periods',
        orderBy: 'year DESC, period DESC',
      );

      return results.map((json) => FiscalPeriodModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalStorageException('Failed to get fiscal periods: ${e.toString()}');
    }
  }

  @override
  Future<FiscalPeriodModel?> getPeriodForDate(DateTime date) async {
    try {
      final timestamp = date.millisecondsSinceEpoch ~/ 1000;

      final results = await database.query(
        'fiscal_periods',
        where: 'start_date <= ? AND end_date >= ?',
        whereArgs: [timestamp, timestamp],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return FiscalPeriodModel.fromJson(results.first);
    } catch (e) {
      throw LocalStorageException('Failed to get period for date: ${e.toString()}');
    }
  }

  @override
  Future<FiscalPeriodModel?> getPeriod(int year, int period) async {
    try {
      final results = await database.query(
        'fiscal_periods',
        where: 'year = ? AND period = ?',
        whereArgs: [year, period],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return FiscalPeriodModel.fromJson(results.first);
    } catch (e) {
      throw LocalStorageException('Failed to get period: ${e.toString()}');
    }
  }

  @override
  Future<int> createPeriod(FiscalPeriodModel period) async {
    try {
      // Check for duplicate
      final existing = await getPeriod(period.year, period.period);
      if (existing != null) {
        throw LocalStorageException('Fiscal period already exists: ${period.year}-${period.period}');
      }

      final id = await database.insert(
        'fiscal_periods',
        period.toJson(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return id;
    } catch (e) {
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to create fiscal period: ${e.toString()}');
    }
  }

  @override
  Future<void> closePeriod(int periodId, int userId) async {
    try {
      await database.update(
        'fiscal_periods',
        {
          'status': 1,
          'is_closed': 1,
          'closed_by': userId,
          'closed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [periodId],
      );
    } catch (e) {
      throw LocalStorageException('Failed to close period: ${e.toString()}');
    }
  }

  @override
  Future<void> reopenPeriod(int periodId) async {
    try {
      await database.update(
        'fiscal_periods',
        {
          'status': 0,
          'is_closed': 0,
          'closed_by': null,
          'closed_at': null,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [periodId],
      );
    } catch (e) {
      throw LocalStorageException('Failed to reopen period: ${e.toString()}');
    }
  }

  @override
  Future<void> lockPeriod(int periodId) async {
    try {
      await database.update(
        'fiscal_periods',
        {
          'status': 2,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [periodId],
      );
    } catch (e) {
      throw LocalStorageException('Failed to lock period: ${e.toString()}');
    }
  }
}
