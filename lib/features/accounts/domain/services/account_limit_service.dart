import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';

abstract class AccountLimitService {
  /// Check if an account can perform a debit transaction
  Future<Either<Failure, bool>> canDebit({
    required int accountId,
    required double amount,
    required int currencyId,
  });

  /// Check if an account can perform a credit transaction
  Future<Either<Failure, bool>> canCredit({
    required int accountId,
    required double amount,
    required int currencyId,
  });

  /// Validate a transaction against account limits
  Future<Either<Failure, AccountLimitValidationResult>> validateTransaction({
    required int accountId,
    required double debitAmount,
    required double creditAmount,
    required int currencyId,
  });

  /// Update account usage after a transaction
  Future<Either<Failure, void>> updateAccountUsage({
    required int accountId,
    required double debitAmount,
    required double creditAmount,
    required int currencyId,
  });

  /// Get account limit for a specific account and currency
  Future<Either<Failure, AccountLimitEntity?>> getAccountLimit({
    required int accountId,
    required int currencyId,
  });

  /// Get all account limits
  Future<Either<Failure, List<AccountLimitEntity>>> getAllAccountLimits();

  /// Get accounts that are near their limits (warning or critical)
  Future<Either<Failure, List<AccountLimitEntity>>> getAccountsNearLimit();

  /// Create or update account limit
  Future<Either<Failure, int>> saveAccountLimit(AccountLimitEntity limit);

  /// Delete account limit
  Future<Either<Failure, void>> deleteAccountLimit(int id);

  /// Reset account usage (usually at period end)
  Future<Either<Failure, void>> resetAccountUsage({
    required int accountId,
    required int currencyId,
  });

  /// Batch validate multiple transactions
  Future<Either<Failure, List<AccountLimitValidationResult>>> batchValidate(
    List<TransactionValidationRequest> requests,
  );
}

class AccountLimitValidationResult {
  final bool isValid;
  final AccountLimitEntity? limit;
  final List<String> violations;
  final UsageLevel? newUsageLevel;
  final double? availableDebit;
  final double? availableCredit;

  const AccountLimitValidationResult({
    required this.isValid,
    this.limit,
    this.violations = const [],
    this.newUsageLevel,
    this.availableDebit,
    this.availableCredit,
  });

  bool get hasWarning => newUsageLevel == UsageLevel.warning;
  bool get hasCritical => newUsageLevel == UsageLevel.critical;
}

class TransactionValidationRequest {
  final int accountId;
  final double debitAmount;
  final double creditAmount;
  final int currencyId;
  final String? description;

  const TransactionValidationRequest({
    required this.accountId,
    required this.debitAmount,
    required this.creditAmount,
    required this.currencyId,
    this.description,
  });
}
