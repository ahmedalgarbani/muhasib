import 'package:muhasib/core/errors/exceptions.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/voucher_entity.dart';
import '../models/voucher_model.dart';

abstract class VoucherLocalDataSource {
  Future<List<VoucherModel>> getVouchers({VoucherType? type});
  Future<VoucherModel> getVoucher(int id);
  Future<int> insertVoucher(VoucherModel voucher);
  Future<void> updateVoucher(VoucherModel voucher);
  Future<void> deleteVoucher(int id);
  Future<int> generateVoucherNumber(VoucherType type);
}

class VoucherLocalDataSourceImpl implements VoucherLocalDataSource {
  static const String _vouchersTable = 'vouchers';
  static const String _voucherLinesTable = 'voucher_lines';
  static const String _accountsTable = 'accounts';

  final Database database;

  VoucherLocalDataSourceImpl({required this.database});

  @override
  Future<List<VoucherModel>> getVouchers({VoucherType? type}) async {
    try {
      final whereClause = type != null ? 'WHERE v.type = ?' : '';
      final whereArgs = type != null ? [type.value] : <Object?>[];

      final rows = await database.rawQuery(
        '''
        SELECT v.*, a.name AS account_name
        FROM $_vouchersTable v
        LEFT JOIN $_accountsTable a ON a.id = v.account_id
        $whereClause
        ORDER BY v.date DESC, v.id DESC
        ''',
        whereArgs,
      );

      final vouchers = <VoucherModel>[];

      for (final row in rows) {
        final lines = await _getVoucherLines(row['id'] as int);
        vouchers.add(VoucherModel.fromJson(row, lines: lines));
      }

      return vouchers;
    } catch (e) {
      throw LocalStorageException(
        'Failed to load vouchers: ${e.toString()}',
      );
    }
  }

  @override
  Future<VoucherModel> getVoucher(int id) async {
    try {
      final rows = await database.rawQuery(
        '''
        SELECT v.*, a.name AS account_name
        FROM $_vouchersTable v
        LEFT JOIN $_accountsTable a ON a.id = v.account_id
        WHERE v.id = ?
        LIMIT 1
        ''',
        [id],
      );

      if (rows.isEmpty) {
        throw LocalStorageException('Voucher with id $id not found');
      }

      final lines = await _getVoucherLines(id);
      return VoucherModel.fromJson(rows.first, lines: lines);
    } catch (e) {
      throw LocalStorageException(
        'Failed to get voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> insertVoucher(VoucherModel voucher) async {
    try {
      return await database.transaction((txn) async {
        final payload = voucher.toJson();
        payload['creation_time'] ??= DateTime.now().millisecondsSinceEpoch;
        payload['last_modification_time'] ??=
            DateTime.now().millisecondsSinceEpoch;

        final voucherId = await txn.insert(
          _vouchersTable,
          payload,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        for (final line in voucher.lines) {
          final model =
              line is VoucherLineModel ? line : VoucherLineModel.fromEntity(line);
          final linePayload = model.toJson(voucherId: voucherId);

          await txn.insert(
            _voucherLinesTable,
            linePayload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        return voucherId;
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to insert voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateVoucher(VoucherModel voucher) async {
    if (voucher.id == null) {
      throw LocalStorageException('Voucher id is required for update');
    }

    try {
      await database.transaction((txn) async {
        final updated = await txn.update(
          _vouchersTable,
          voucher.toJson(),
          where: 'id = ?',
          whereArgs: [voucher.id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        if (updated == 0) {
          throw LocalStorageException(
            'Voucher with id ${voucher.id} was not found',
          );
        }

        await txn.delete(
          _voucherLinesTable,
          where: 'vouchers_id = ?',
          whereArgs: [voucher.id],
        );

        for (final line in voucher.lines) {
          final model =
              line is VoucherLineModel ? line : VoucherLineModel.fromEntity(line);
          final payload = model.toJson(voucherId: voucher.id!);

          await txn.insert(
            _voucherLinesTable,
            payload,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
    } catch (e) {
      throw LocalStorageException(
        'Failed to update voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteVoucher(int id) async {
    try {
      final deleted = await database.delete(
        _vouchersTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deleted == 0) {
        throw LocalStorageException('Voucher with id $id not found');
      }
    } catch (e) {
      throw LocalStorageException(
        'Failed to delete voucher: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> generateVoucherNumber(VoucherType type) async {
    try {
      final result = await database.rawQuery(
        '''
        SELECT COALESCE(MAX(number), 0) + 1 AS next_number
        FROM $_vouchersTable
        WHERE type = ?
        ''',
        [type.value],
      );

      if (result.isEmpty) return 1;
      final value = result.first['next_number'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 1;
    } catch (e) {
      throw LocalStorageException(
        'Failed to generate voucher number: ${e.toString()}',
      );
    }
  }

  Future<List<VoucherLineModel>> _getVoucherLines(int voucherId) async {
    final lines = await database.rawQuery(
      '''
      SELECT vl.*, a.name AS account_name
      FROM $_voucherLinesTable vl
      LEFT JOIN $_accountsTable a ON a.id = vl.account_id
      WHERE vl.vouchers_id = ?
      ORDER BY vl.id ASC
      ''',
      [voucherId],
    );

    return lines.map((e) => VoucherLineModel.fromJson(e)).toList();
  }
}

