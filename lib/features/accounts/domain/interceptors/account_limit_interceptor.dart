import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';

/// Interceptor to check account limits before transactions
class AccountLimitInterceptor {
  final AccountLimitService limitService;

  AccountLimitInterceptor({required this.limitService});

  /// Intercept and validate a journal entry before saving
  Future<Either<Failure, bool>> validateJournalEntry({
    required List<JournalEntryLineValidation> lines,
  }) async {
    try {
      // Group lines by account and currency
      final groupedLines = <String, JournalEntryLineValidation>{};
      
      for (final line in lines) {
        final key = '${line.accountId}_${line.currencyId}';
        if (groupedLines.containsKey(key)) {
          groupedLines[key] = JournalEntryLineValidation(
            accountId: line.accountId,
            currencyId: line.currencyId,
            debitAmount: groupedLines[key]!.debitAmount + line.debitAmount,
            creditAmount: groupedLines[key]!.creditAmount + line.creditAmount,
          );
        } else {
          groupedLines[key] = line;
        }
      }

      // Validate each account
      final violations = <String>[];
      
      for (final line in groupedLines.values) {
        final result = await limitService.validateTransaction(
          accountId: line.accountId,
          debitAmount: line.debitAmount,
          creditAmount: line.creditAmount,
          currencyId: line.currencyId,
        );

        result.fold(
          (failure) => violations.add('خطأ في التحقق من حساب ${line.accountId}: ${failure.message}'),
          (validation) {
            if (!validation.isValid) {
              violations.addAll(validation.violations);
            } else if (validation.hasWarning) {
              // Log warning but don't block
              print('تحذير: الحساب ${line.accountId} يقترب من الحد المسموح');
            }
          },
        );
      }

      if (violations.isNotEmpty) {
        return Left(ValidationFailure(
          message: 'فشل التحقق من حدود الحسابات',
          violations: violations,
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Intercept and validate an invoice before saving
  Future<Either<Failure, bool>> validateInvoice({
    required int accountId,
    required double totalAmount,
    required int currencyId,
    required InvoiceType invoiceType,
  }) async {
    try {
      double debitAmount = 0;
      double creditAmount = 0;

      // Determine debit/credit based on invoice type
      switch (invoiceType) {
        case InvoiceType.sales:
        case InvoiceType.salesReturn:
          creditAmount = totalAmount;
          break;
        case InvoiceType.purchase:
        case InvoiceType.purchaseReturn:
          debitAmount = totalAmount;
          break;
        case InvoiceType.quotation:
          // Quotations don't affect limits
          return const Right(true);
      }

      final result = await limitService.validateTransaction(
        accountId: accountId,
        debitAmount: debitAmount,
        creditAmount: creditAmount,
        currencyId: currencyId,
      );

      return result.fold(
        (failure) => Left(failure),
        (validation) {
          if (!validation.isValid) {
            return Left(ValidationFailure(
              message: 'تجاوز حدود الحساب',
              violations: validation.violations,
            ));
          }
          
          // Show warning if near limit
          if (validation.hasWarning) {
            _showWarningNotification(
              accountId: accountId,
              usageLevel: validation.newUsageLevel!,
              availableDebit: validation.availableDebit,
              availableCredit: validation.availableCredit,
            );
          }
          
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Intercept and validate a payment/receipt voucher
  Future<Either<Failure, bool>> validateVoucher({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required int currencyId,
  }) async {
    try {
      // Validate from account (credit)
      final fromResult = await limitService.validateTransaction(
        accountId: fromAccountId,
        debitAmount: 0,
        creditAmount: amount,
        currencyId: currencyId,
      );

      if (fromResult.isLeft()) {
        return fromResult.fold(
          (failure) => Left(failure),
          (_) => const Right(true),
        );
      }

      // Validate to account (debit)
      final toResult = await limitService.validateTransaction(
        accountId: toAccountId,
        debitAmount: amount,
        creditAmount: 0,
        currencyId: currencyId,
      );

      return toResult.fold(
        (failure) => Left(failure),
        (validation) {
          if (!validation.isValid) {
            return Left(ValidationFailure(
              message: 'تجاوز حدود الحساب',
              violations: validation.violations,
            ));
          }
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Update account usage after successful transaction
  Future<Either<Failure, void>> updateUsageAfterTransaction({
    required List<JournalEntryLineValidation> lines,
  }) async {
    try {
      for (final line in lines) {
        final result = await limitService.updateAccountUsage(
          accountId: line.accountId,
          debitAmount: line.debitAmount,
          creditAmount: line.creditAmount,
          currencyId: line.currencyId,
        );

        if (result.isLeft()) {
          return result;
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Check accounts that are near their limits
  Future<Either<Failure, List<AccountLimitWarning>>> checkAccountsNearLimit() async {
    try {
      final result = await limitService.getAccountsNearLimit();

      return result.fold(
        (failure) => Left(failure),
        (limits) {
          final warnings = limits.map((limit) {
            return AccountLimitWarning(
              accountId: limit.accountId,
              accountName: limit.accountName,
              usageLevel: limit.usageLevel,
              debitUsage: limit.debitUsagePercentage,
              creditUsage: limit.creditUsagePercentage,
              availableDebit: limit.availableDebit,
              availableCredit: limit.availableCredit,
            );
          }).toList();
          
          return Right(warnings);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  void _showWarningNotification({
    required int accountId,
    required UsageLevel usageLevel,
    double? availableDebit,
    double? availableCredit,
  }) {
    // This would trigger a notification in the UI
    // Implementation depends on your notification system
    print('تحذير: الحساب $accountId وصل إلى مستوى $usageLevel');
    if (availableDebit != null) {
      print('المتاح للمدين: ${availableDebit.toStringAsFixed(2)}');
    }
    if (availableCredit != null) {
      print('المتاح للدائن: ${availableCredit.toStringAsFixed(2)}');
    }
  }
}

class JournalEntryLineValidation {
  final int accountId;
  final int currencyId;
  final double debitAmount;
  final double creditAmount;

  const JournalEntryLineValidation({
    required this.accountId,
    required this.currencyId,
    required this.debitAmount,
    required this.creditAmount,
  });
}

class AccountLimitWarning {
  final int accountId;
  final String accountName;
  final UsageLevel usageLevel;
  final double debitUsage;
  final double creditUsage;
  final double availableDebit;
  final double availableCredit;

  const AccountLimitWarning({
    required this.accountId,
    required this.accountName,
    required this.usageLevel,
    required this.debitUsage,
    required this.creditUsage,
    required this.availableDebit,
    required this.availableCredit,
  });
}

enum InvoiceType {
  sales,
  purchase,
  salesReturn,
  purchaseReturn,
  quotation,
}

class ValidationFailure extends Failure {
  final List<String> violations;

  ValidationFailure({
    required String message,
    this.violations = const [],
  }) : super(message);

  @override
  String toString() {
    if (violations.isEmpty) return message;
    return '$message:\n${violations.join('\n')}';
  }
}
