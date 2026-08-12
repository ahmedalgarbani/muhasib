/// Example of integrating both Account Limits and Account Connections validation
/// 
/// This example shows how to use both validation systems together in a Cubit
/// to ensure all requirements are met before allowing operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/presentation/mixins/account_limit_mixin.dart';
import 'package:muhasib/features/accounts/presentation/mixins/account_connect_validation_mixin.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/domain/services/account_connect_validator.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';

/// Example Sales Cubit with complete validation
class SalesCubitWithValidations extends Cubit<dynamic> 
    with AccountLimitMixin, AccountConnectValidationMixin {
  
  final AccountLimitService accountLimitService;
  final AccountConnectValidator accountConnectValidator;

  SalesCubitWithValidations({
    required this.accountLimitService,
    required this.accountConnectValidator,
    required dynamic initialState,
  }) : super(initialState) {
    // Initialize both validators
    initializeLimitChecker(accountLimitService);
    initializeConnectValidator(accountConnectValidator);
  }

  /// Complete validation before saving a sales invoice
  Future<bool> validateAndSaveInvoice({
    required int customerAccountId,
    required double totalAmount,
    required int currencyId,
    required BuildContext context,
  }) async {
    // Step 1: Check account connections
    print('Checking account connections...');
    final hasConnections = await validateSalesConnections(context);
    
    if (!hasConnections) {
      print('Account connections validation failed');
      // Dialog will be shown automatically by the mixin
      return false;
    }
    
    print('Account connections validated successfully');

    // Step 2: Get connected account IDs
    final customersAccountId = await getConnectedAccountId(2); // العملاء
    final salesAccountId = await getConnectedAccountId(7); // المبيعات
    
    if (customersAccountId == null || salesAccountId == null) {
      print('Could not retrieve connected account IDs');
      return false;
    }

    // Step 3: Check account limits
    print('Checking account limits...');
    final canSave = await canSaveInvoice(
      accountId: customersAccountId,
      totalAmount: totalAmount,
      currencyId: currencyId,
      invoiceType: InvoiceType.sales,
      context: context,
    );

    if (!canSave) {
      print('Account limits validation failed');
      // Dialog will be shown automatically by the mixin
      return false;
    }

    print('Account limits validated successfully');

    // Step 4: Proceed with saving the invoice
    try {
      print('Saving invoice...');
      // Your actual save logic here
      // await saveInvoice(...);

      // Step 5: Update account usage after successful save
      await updateAccountUsage(
        lines: [
          JournalEntryLineValidation(
            accountId: customersAccountId,
            currencyId: currencyId,
            debitAmount: totalAmount, // Customer account is debited
            creditAmount: 0,
          ),
          JournalEntryLineValidation(
            accountId: salesAccountId,
            currencyId: currencyId,
            debitAmount: 0,
            creditAmount: totalAmount, // Sales account is credited
          ),
        ],
      );

      print('Invoice saved successfully');

      // Step 6: Check for warnings (accounts near limit)
      await checkAccountWarnings(context);

      return true;
    } catch (e) {
      print('Error saving invoice: $e');
      _showErrorDialog(context, 'خطأ في حفظ الفاتورة: $e');
      return false;
    }
  }

  /// Validate before purchase operation
  Future<bool> validateAndSavePurchase({
    required int supplierAccountId,
    required double totalAmount,
    required int currencyId,
    required BuildContext context,
  }) async {
    // Check connections
    if (!await validatePurchaseConnections(context)) {
      return false;
    }

    // Get connected accounts
    final suppliersAccountId = await getConnectedAccountId(3); // الموردون
    final purchasesAccountId = await getConnectedAccountId(10); // المشتريات
    
    if (suppliersAccountId == null || purchasesAccountId == null) {
      return false;
    }

    // Check limits for both accounts
    final supplierLimitOk = await canSaveInvoice(
      accountId: suppliersAccountId,
      totalAmount: totalAmount,
      currencyId: currencyId,
      invoiceType: InvoiceType.purchase,
      context: context,
    );

    if (!supplierLimitOk) {
      return false;
    }

    // Proceed with save...
    return true;
  }

  /// Validate before payment/receipt
  Future<bool> validateAndSavePayment({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required int currencyId,
    required BuildContext context,
  }) async {
    // Check payment connections (banks/cash)
    if (!await validatePaymentConnections(context)) {
      return false;
    }

    // Check limits
    final canPay = await canSaveVoucher(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      currencyId: currencyId,
      context: context,
    );

    if (!canPay) {
      return false;
    }

    // Proceed with payment...
    return true;
  }

  /// Check system readiness on startup
  Future<void> checkSystemReadiness(BuildContext context) async {
    print('Checking system readiness...');
    
    // Check all account connections
    await checkConnectionStatus(context);
    
    // Check for accounts near limits
    await checkAccountWarnings(context);
    
    print('System readiness check complete');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
