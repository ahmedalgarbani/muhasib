import 'package:flutter/material.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';

/// Mixin to add account limit checking capabilities to Cubits
mixin AccountLimitMixin {
  AccountLimitInterceptor? _limitInterceptor;

  void initializeLimitChecker(AccountLimitService limitService) {
    _limitInterceptor = AccountLimitInterceptor(limitService: limitService);
  }

  /// Check if a journal entry can be saved based on account limits
  Future<bool> canSaveJournalEntry({
    required List<JournalEntryLineValidation> lines,
    required BuildContext context,
  }) async {
    if (_limitInterceptor == null)
      return true; // No limit checking if not initialized

    final result = await _limitInterceptor!.validateJournalEntry(lines: lines);

    return result.fold((failure) {
      _showLimitViolationDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Check if an invoice can be saved based on account limits
  Future<bool> canSaveInvoice({
    required int accountId,
    required double totalAmount,
    required int currencyId,
    required InvoiceType invoiceType,
    required BuildContext context,
  }) async {
    if (_limitInterceptor == null) return true;

    final result = await _limitInterceptor!.validateInvoice(
      accountId: accountId,
      totalAmount: totalAmount,
      currencyId: currencyId,
      invoiceType: invoiceType,
    );

    return result.fold((failure) {
      _showLimitViolationDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Check if a voucher can be saved based on account limits
  Future<bool> canSaveVoucher({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required int currencyId,
    required BuildContext context,
  }) async {
    if (_limitInterceptor == null) return true;

    final result = await _limitInterceptor!.validateVoucher(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      currencyId: currencyId,
    );

    return result.fold((failure) {
      _showLimitViolationDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Update account usage after successful transaction
  Future<void> updateAccountUsage({
    required List<JournalEntryLineValidation> lines,
  }) async {
    if (_limitInterceptor == null) return;

    await _limitInterceptor!.updateUsageAfterTransaction(lines: lines);
  }

  /// Check and show warnings for accounts near limit
  Future<void> checkAccountWarnings(BuildContext context) async {
    if (_limitInterceptor == null) return;

    final result = await _limitInterceptor!.checkAccountsNearLimit();

    result.fold(
      (failure) => null, // Silently fail for warnings
      (warnings) {
        if (warnings.isNotEmpty) {
          _showWarningsDialog(context, warnings);
        }
      },
    );
  }

  void _showLimitViolationDialog(BuildContext context, Failure failure) {
    String message = failure.message;
    List<String> violations = [];

    if (failure is ValidationFailure) {
      violations = failure.violations;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('تجاوز حدود الحساب'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (violations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'التفاصيل:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...violations.map(
                  (violation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.close, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            violation,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showWarningsDialog(
    BuildContext context,
    List<AccountLimitWarning> warnings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('تحذير: حسابات تقترب من الحد المسموح'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: warnings.map((warning) {
              Color usageColor = Colors.orange;
              IconData icon = Icons.warning_amber_rounded;

              if (warning.usageLevel == UsageLevel.critical) {
                usageColor = Colors.red;
                icon = Icons.error_outline;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: usageColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              warning.accountName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (warning.debitUsage > 70)
                        _buildUsageRow(
                          'استخدام المدين',
                          warning.debitUsage,
                          warning.availableDebit,
                          usageColor,
                        ),
                      if (warning.creditUsage > 70)
                        _buildUsageRow(
                          'استخدام الدائن',
                          warning.creditUsage,
                          warning.availableCredit,
                          usageColor,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(
    String label,
    double usagePercentage,
    double available,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                '${usagePercentage.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: usagePercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            'المتاح: ${available.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
