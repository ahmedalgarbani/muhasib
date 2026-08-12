import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

class SelectPurchaseForReturnPage extends StatefulWidget {
  const SelectPurchaseForReturnPage({super.key});

  @override
  State<SelectPurchaseForReturnPage> createState() =>
      _SelectPurchaseForReturnPageState();
}

class _SelectPurchaseForReturnPageState
    extends State<SelectPurchaseForReturnPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(int tsSeconds) {
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000));
  }

  Future<void> _confirmCreateReturn(
    BuildContext context,
    InvoiceEntity parent,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء مردود مشتريات'),
        content: Text('هل تريد إنشاء مردود كامل للفاتورة ${parent.number}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final now = DateTime.now();
    final returnNumber =
        'PR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';

    final returnInvoice = InvoiceEntity(
      invoiceType: InvoiceType.purchaseReturn.value,
      number: returnNumber,
      date: now.millisecondsSinceEpoch ~/ 1000,
      statement: parent.statement,
      amount: parent.amount,
      totalAmount: parent.totalAmount,

      taxAmt: parent.taxAmt,
      taxRatio: parent.taxRatio,
      discountAmt: parent.discountAmt,
      discountRatio: parent.discountRatio,
      otherFeeAmt: parent.otherFeeAmt,
      otherFeeNetRatio: parent.otherFeeNetRatio,
      netRevenueAmt: parent.netRevenueAmt,
      totalAmountAfterDiscount: parent.totalAmountAfterDiscount,
      finalAmt: parent.finalAmt,
      currencyId: parent.currencyId,
      stockId: parent.stockId,
      customerId: parent.customerId,
      taxId: parent.taxId,
      otherFeeAccountId: parent.otherFeeAccountId,
      // Return uses same cash/credit mode as original by default
      invoiceTransType: parent.invoiceTransType,
      parentInvoiceId: parent.id,
      parentInvoiceNumber: parent.number,
      paymentStatus: 0,
      shippingAddress: parent.shippingAddress,
      dueDate: parent.dueDate,
      lines: parent.lines,
    );

    if (parent.id == null) return;
    context.read<PurchasesCubit>().createPurchaseReturn(
      returnInvoice,
      parent.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PurchasesCubit>()..loadPurchaseInvoices(),
      child: Scaffold(
        appBar: CustomAppBar(title: 'اختر فاتورة مشتريات للمردود'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'بحث برقم الفاتورة...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final q = v.trim();
                  if (q.isEmpty) {
                    context.read<PurchasesCubit>().loadPurchaseInvoices();
                  } else {
                    context.read<PurchasesCubit>().searchPurchases(q);
                  }
                },
              ),
            ),
            Expanded(
              child: BlocConsumer<PurchasesCubit, PurchasesState>(
                listener: (context, state) {
                  if (state is PurchaseReturnCreated) {
                    AppToast.showSuccess(context, 'تم إنشاء مردود المشتريات');

                    Navigator.of(context).pop(true);
                  }
                  if (state is PurchasesError) {
                    AppToast.showError(context, state.message);
                  }
                },
                builder: (context, state) {
                  if (state is PurchasesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is PurchaseInvoicesLoaded) {
                    final purchases = state.invoices
                        .where(
                          (e) =>
                              e.invoiceType ==
                              InvoiceType.purchaseInvoice.value,
                        )
                        .toList();
                    if (purchases.isEmpty) {
                      return const Center(
                        child: Text('لا توجد فواتير مشتريات'),
                      );
                    }
                    return ListView.separated(
                      itemCount: purchases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final inv = purchases[i];
                        return ListTile(
                          title: Text(inv.number),
                          subtitle: Text(_formatDate(inv.date)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _confirmCreateReturn(context, inv),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('تحميل فواتير المشتريات...'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
