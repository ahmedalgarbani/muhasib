import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/voucher_repository.dart';
import 'package:muhasib/features/customers/domain/repositories/customer_repository.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoices.dart';

part 'main_state.dart';

class MainCubit extends Cubit<MainState> {
  final CustomerRepository _customerRepository;
  final GetInvoices _getInvoices;
  final PurchaseRepository _purchaseRepository;
  final VoucherRepository _voucherRepository;

  MainCubit({
    required CustomerRepository customerRepository,
    required GetInvoices getInvoices,
    required PurchaseRepository purchaseRepository,
    required VoucherRepository voucherRepository,
  }) : _customerRepository = customerRepository,
       _getInvoices = getInvoices,
       _purchaseRepository = purchaseRepository,
       _voucherRepository = voucherRepository,
       super(MainInitial());

  Future<void> loadDashboardData() async {
    emit(MainLoading());

    try {
      int customersCount = 0;
      int suppliersCount = 0;

      final customersRes = await _customerRepository.getCustomers();
      customersRes.fold((_) => null, (list) => customersCount = list.length);

      final suppliersRes = await _customerRepository.getSuppliers();
      suppliersRes.fold((_) => null, (list) => suppliersCount = list.length);

      final List<RecentTransactionEntity> allTransactions = [];

      // Sales Invoices
      final salesRes = await _getInvoices(params: NoParams());
      salesRes.fold((_) => null, (invoices) {
        for (final inv in invoices) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
            inv.date * 1000,
          );
          allTransactions.add(
            RecentTransactionEntity(
              title: 'فاتورة مبيعات #${inv.number}',
              amount: NumberFormatter.formatNumber(inv.totalAmount ?? 0),
              date: DateFormatter.formatRelativeDate(dt),
              isIncome: true,
              icon: Icons.shopping_cart,
              timestamp: dt,
            ),
          );
        }
      });

      // Purchase Invoices
      final purchaseRes = await _purchaseRepository.getPurchaseInvoices();
      purchaseRes.fold((_) => null, (invoices) {
        for (final inv in invoices) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
            inv.date * 1000,
          );
          allTransactions.add(
            RecentTransactionEntity(
              title: 'فاتورة شراء #${inv.number}',
              amount: NumberFormatter.formatNumber(inv.totalAmount ?? 0),
              date: DateFormatter.formatRelativeDate(dt),
              isIncome: false,
              icon: Icons.shopping_bag,
              timestamp: dt,
            ),
          );
        }
      });

      // Vouchers
      final voucherRes = await _voucherRepository.getVouchers();
      voucherRes.fold((_) => null, (vouchers) {
        for (final v in vouchers) {
          final isReceipt = v.type == VoucherType.receipt;
          allTransactions.add(
            RecentTransactionEntity(
              title: isReceipt
                  ? 'سند قبض #${v.number}'
                  : 'سند صرف #${v.number}',
              amount: NumberFormatter.formatNumber(v.amount),
              date: DateFormatter.formatRelativeDate(v.date),
              isIncome: isReceipt,
              icon: isReceipt ? Icons.download_rounded : Icons.upload_rounded,
              timestamp: v.date,
            ),
          );
        }
      });

      // Sort by timestamp descending
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final recentFive = allTransactions.take(5).toList();

      emit(
        MainDashboardLoaded(
          customersCount: customersCount,
          suppliersCount: suppliersCount,
          recentTransactions: recentFive,
        ),
      );
    } catch (e) {
      emit(MainError('فشل تحميل بيانات الرئيسية: $e'));
    }
  }
}
