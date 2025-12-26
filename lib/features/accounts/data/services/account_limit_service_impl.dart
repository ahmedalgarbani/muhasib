import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/data/datasources/account_limit_local_datasource.dart';
import 'package:muhasib/features/accounts/data/models/account_limit_model.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';

class AccountLimitServiceImpl implements AccountLimitService {
  final AccountLimitLocalDataSource localDataSource;

  AccountLimitServiceImpl({required this.localDataSource});

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

          if (debitAmount > 0 && !limit.canAddDebit(debitAmount)) {
            violations.add(
              'تجاوز حد المدين: المطلوب ${debitAmount.toStringAsFixed(2)}, '
              'المتاح ${limit.availableDebit.toStringAsFixed(2)}',
            );
            isValid = false;
          }

          if (creditAmount > 0 && !limit.canAddCredit(creditAmount)) {
            violations.add(
              'تجاوز حد الدائن: المطلوب ${creditAmount.toStringAsFixed(2)}, '
              'المتاح ${limit.availableCredit.toStringAsFixed(2)}',
            );
            isValid = false;
          }

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
      await localDataSource.updateCurrentUsage(
        accountId: accountId,
        currencyId: currencyId,
        debitChange: debitAmount,
        creditChange: creditAmount,
      );

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
      final model = await localDataSource.getByAccountAndCurrency(
        accountId: accountId,
        currencyId: currencyId,
      );
      return Right(model);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountLimitEntity>>> getAllAccountLimits() async {
    try {
      final limits = await localDataSource.getAll();
      return Right(limits);
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
      final model = AccountLimitModel.fromEntity(limit);
      final id = await localDataSource.save(model);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccountLimit(int id) async {
    try {
      await localDataSource.delete(id);
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
      await localDataSource.resetUsage(
        accountId: accountId,
        currencyId: currencyId,
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
}
