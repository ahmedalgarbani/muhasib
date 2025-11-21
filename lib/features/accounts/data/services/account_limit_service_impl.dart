import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';

class AccountLimitServiceImpl implements AccountLimitService {
  final DatabaseService databaseService;

  AccountLimitServiceImpl({required this.databaseService});

  @override
  Future<Either<Failure, bool>> canDebit({
    required int accountId,
    required double amount,
    required int currencyId,
  }) async {
    try {
      final limitResult = await getAccountLimit(
        accountId: accountId,
        currencyId: currencyId,
      );

      return limitResult.fold(
        (failure) => Left(failure),
        (limit) {
          if (limit == null) return const Right(true); // No limit set
          return Right(limit.canAddDebit(amount));
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canCredit({
    required int accountId,
    required double amount,
    required int currencyId,
  }) async {
    try {
      final limitResult = await getAccountLimit(
        accountId: accountId,
        currencyId: currencyId,
      );

      return limitResult.fold(
        (failure) => Left(failure),
        (limit) {
          if (limit == null) return const Right(true); // No limit set
          return Right(limit.canAddCredit(amount));
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountLimitValidationResult>> validateTransaction({
    required int accountId,
    required double debitAmount,
    required double creditAmount,
    required int currencyId,
  }) async {
    try {
      final limitResult = await getAccountLimit(
        accountId: accountId,
        currencyId: currencyId,
      );

      return limitResult.fold(
        (failure) => Left(failure),
        (limit) {
          if (limit == null) {
            // No limit set, transaction is valid
            return const Right(AccountLimitValidationResult(
              isValid: true,
              violations: [],
            ));
          }

          final violations = <String>[];
          bool isValid = true;

          // Check debit limit
          if (debitAmount > 0 && !limit.canAddDebit(debitAmount)) {
            violations.add(
              'تجاوز حد المدين: المطلوب ${debitAmount.toStringAsFixed(2)}, '
              'المتاح ${limit.availableDebit.toStringAsFixed(2)}',
            );
            isValid = false;
          }

          // Check credit limit
          if (creditAmount > 0 && !limit.canAddCredit(creditAmount)) {
            violations.add(
              'تجاوز حد الدائن: المطلوب ${creditAmount.toStringAsFixed(2)}, '
              'المتاح ${limit.availableCredit.toStringAsFixed(2)}',
            );
            isValid = false;
          }

          // Calculate new usage level
          final newDebit = limit.currentDebit + debitAmount;
          final newCredit = limit.currentCredit + creditAmount;
          final tempLimit = limit.copyWith(
            currentDebit: newDebit,
            currentCredit: newCredit,
          );

          return Right(AccountLimitValidationResult(
            isValid: isValid,
            limit: limit,
            violations: violations,
            newUsageLevel: tempLimit.usageLevel,
            availableDebit: limit.availableDebit,
            availableCredit: limit.availableCredit,
          ));
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAccountUsage({
    required int accountId,
    required double debitAmount,
    required double creditAmount,
    required int currencyId,
  }) async {
    try {
      final db = await databaseService.database;

      await db.transaction((txn) async {
        // Get current limit
        final limits = await txn.query(
          'account_limits',
          where: 'account_id = ? AND currency_id = ? AND is_active = 1',
          whereArgs: [accountId, currencyId],
          limit: 1,
        );

        if (limits.isNotEmpty) {
          final limit = limits.first;
          final currentDebit = (limit['current_debit'] as double? ?? 0.0);
          final currentCredit = (limit['current_credit'] as double? ?? 0.0);

          await txn.update(
            'account_limits',
            {
              'current_debit': currentDebit + debitAmount,
              'current_credit': currentCredit + creditAmount,
              'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            },
            where: 'id = ?',
            whereArgs: [limit['id']],
          );

          // Log the usage update
          await _logUsageUpdate(
            txn,
            accountId: accountId,
            currencyId: currencyId,
            debitAmount: debitAmount,
            creditAmount: creditAmount,
          );
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountLimitEntity?>> getAccountLimit({
    required int accountId,
    required int currencyId,
  }) async {
    try {
      final db = await databaseService.database;

      final limits = await db.query(
        'account_limits',
        where: 'account_id = ? AND currency_id = ? AND is_active = 1',
        whereArgs: [accountId, currencyId],
        limit: 1,
      );

      if (limits.isEmpty) return const Right(null);

      final limit = _mapToEntity(limits.first);
      return Right(limit);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountLimitEntity>>> getAllAccountLimits() async {
    try {
      final db = await databaseService.database;

      final limits = await db.rawQuery('''
        SELECT 
          al.*,
          a.name as account_name,
          a.code as account_code,
          c.code as currency_code
        FROM account_limits al
        JOIN accounts a ON a.id = al.account_id
        JOIN currencies c ON c.id = al.currency_id
        WHERE al.is_active = 1
        ORDER BY a.name, c.code
      ''');

      final entities = limits.map(_mapToEntity).toList();
      return Right(entities);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountLimitEntity>>> getAccountsNearLimit() async {
    try {
      final allLimitsResult = await getAllAccountLimits();

      return allLimitsResult.fold(
        (failure) => Left(failure),
        (limits) {
          final nearLimitAccounts = limits.where((limit) {
            return limit.usageLevel == UsageLevel.warning ||
                   limit.usageLevel == UsageLevel.critical;
          }).toList();

          return Right(nearLimitAccounts);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> saveAccountLimit(AccountLimitEntity limit) async {
    try {
      final db = await databaseService.database;

      final data = {
        'account_id': limit.accountId,
        'currency_id': limit.currencyId,
        'debit_limit': limit.debitLimit,
        'credit_limit': limit.creditLimit,
        'current_debit': limit.currentDebit,
        'current_credit': limit.currentCredit,
        'is_active': limit.isActive ? 1 : 0,
        'creator_id': limit.creatorId ?? 1,
        'creation_time': limit.creationTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      int id;
      if (limit.id != null) {
        await db.update(
          'account_limits',
          data,
          where: 'id = ?',
          whereArgs: [limit.id],
        );
        id = limit.id!;
      } else {
        id = await db.insert('account_limits', data);
      }

      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccountLimit(int id) async {
    try {
      final db = await databaseService.database;

      await db.update(
        'account_limits',
        {
          'is_active': 0,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetAccountUsage({
    required int accountId,
    required int currencyId,
  }) async {
    try {
      final db = await databaseService.database;

      await db.update(
        'account_limits',
        {
          'current_debit': 0.0,
          'current_credit': 0.0,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'account_id = ? AND currency_id = ? AND is_active = 1',
        whereArgs: [accountId, currencyId],
      );

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountLimitValidationResult>>> batchValidate(
    List<TransactionValidationRequest> requests,
  ) async {
    try {
      final results = <AccountLimitValidationResult>[];

      for (final request in requests) {
        final result = await validateTransaction(
          accountId: request.accountId,
          debitAmount: request.debitAmount,
          creditAmount: request.creditAmount,
          currencyId: request.currencyId,
        );

        result.fold(
          (failure) => throw Exception(failure.message),
          (validation) => results.add(validation),
        );
      }

      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  // Helper method to log usage updates
  Future<void> _logUsageUpdate(
    Transaction txn, {
    required int accountId,
    required int currencyId,
    required double debitAmount,
    required double creditAmount,
  }) async {
    await txn.insert('account_limit_logs', {
      'account_id': accountId,
      'currency_id': currencyId,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'transaction_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  // Helper method to map database row to entity
  AccountLimitEntity _mapToEntity(Map<String, dynamic> row) {
    return AccountLimitEntity(
      id: row['id'] as int?,
      accountId: row['account_id'] as int,
      accountName: row['account_name'] as String? ?? '',
      accountCode: row['account_code'] as String? ?? '',
      currencyId: row['currency_id'] as int,
      currencyCode: row['currency_code'] as String? ?? '',
      debitLimit: row['debit_limit'] as double? ?? 0.0,
      creditLimit: row['credit_limit'] as double? ?? 0.0,
      currentDebit: row['current_debit'] as double? ?? 0.0,
      currentCredit: row['current_credit'] as double? ?? 0.0,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      creatorId: row['creator_id'] as int?,
      creationTime: row['creation_time'] as int?,
      lastModificationTime: row['last_modification_time'] as int?,
    );
  }
}
