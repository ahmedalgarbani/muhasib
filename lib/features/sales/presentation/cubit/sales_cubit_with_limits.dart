/// Example of how to integrate account limit checking in SalesCubit
/// 
/// Add this mixin to your SalesCubit:
/// ```dart
/// class SalesCubit extends Cubit<SalesState> with AccountLimitMixin {
/// ```
/// 
/// Then in your constructor, initialize the limit checker:
/// ```dart
/// SalesCubit({
///   required this.createInvoice,
///   required this.accountLimitService, // Add this dependency
///   // ... other dependencies
/// }) : super(SalesInitial()) {
///   initializeLimitChecker(accountLimitService);
/// }
/// ```
/// 
/// Before saving an invoice, check the limits:
/// ```dart
/// Future<void> saveInvoice(Invoice invoice, BuildContext context) async {
///   // Check account limits first
///   final canSave = await canSaveInvoice(
///     accountId: invoice.customerAccountId,
///     totalAmount: invoice.totalAmount,
///     currencyId: invoice.currencyId,
///     invoiceType: InvoiceType.sales,
///     context: context,
///   );
///   
///   if (!canSave) {
///     // The mixin will show an error dialog
///     return;
///   }
///   
///   // Proceed with saving the invoice
///   emit(SalesLoading());
///   
///   final result = await createInvoice(params: invoice);
///   
///   result.fold(
///     (failure) => emit(SalesError(failure.message)),
///     (invoiceId) async {
///       // Update account usage after successful save
///       await updateAccountUsage(
///         lines: [
///           JournalEntryLineValidation(
///             accountId: invoice.customerAccountId,
///             currencyId: invoice.currencyId,
///             debitAmount: 0,
///             creditAmount: invoice.totalAmount,
///           ),
///         ],
///       );
///       
///       emit(SalesSaved(invoiceId));
///       
///       // Check for warnings
///       await checkAccountWarnings(context);
///     },
///   );
/// }
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/presentation/mixins/account_limit_mixin.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';

// Example enhanced SalesCubit with account limit checking
abstract class SalesCubitWithLimits extends Cubit<dynamic> with AccountLimitMixin {
  final AccountLimitService accountLimitService;

  SalesCubitWithLimits({
    required this.accountLimitService,
    required dynamic initialState,
  }) : super(initialState) {
    // Initialize the limit checker from the mixin
    initializeLimitChecker(accountLimitService);
  }

  /// Example method showing how to validate before saving
  Future<bool> validateAndSaveInvoice({
    required int customerAccountId,
    required double totalAmount,
    required int currencyId,
    required BuildContext context,
  }) async {
    // Step 1: Check account limits
    final canSave = await canSaveInvoice(
      accountId: customerAccountId,
      totalAmount: totalAmount,
      currencyId: currencyId,
      invoiceType: InvoiceType.sales,
      context: context,
    );

    if (!canSave) {
      // The mixin will automatically show an error dialog
      return false;
    }

    // Step 2: Proceed with saving
    // ... your save logic here ...

    // Step 3: Update account usage after successful save
    await updateAccountUsage(
      lines: [
        JournalEntryLineValidation(
          accountId: customerAccountId,
          currencyId: currencyId,
          debitAmount: 0,
          creditAmount: totalAmount,
        ),
      ],
    );

    // Step 4: Check for warnings (accounts near limit)
    await checkAccountWarnings(context);

    return true;
  }
}
