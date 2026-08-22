import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

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
    return DateFormatter.formatDate(
      DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000),
    );
  }

  Future<void> _confirmCreateReturn(
    BuildContext context,
    InvoiceEntity parent,
  ) async {
    if (parent.lines.isEmpty) {
      AppToast.showError(context, 'الفاتورة بدون بنود لا يمكن إرجاعها');
      return;
    }
    final resultLines = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => _ReturnQtyDialog(parent: parent),
    );
    if (resultLines == null || resultLines.isEmpty) return;

    // بناء البنود المرجعة بنسب الكميات
    final returnLines = <dynamic>[];
    double retAmount = 0, retDiscount = 0, retTax = 0, retOther = 0, retNet = 0;
    for (final entry in resultLines) {
      final origLine = entry['line'] as dynamic;
      final retQty = entry['qty'] as double;
      final origQty = (origLine.quantity as double);
      if (origQty <= 0) continue;
      final ratio = (retQty / origQty).clamp(0.0, 1.0);
      final lineAmount = (origLine.amount as double) * ratio;
      final lineDiscount = (origLine.discountAmt ?? 0) * ratio;
      final lineTax = (origLine.taxAmt ?? 0) * ratio;
      final lineOther = (origLine.otherFeeAmt ?? 0) * ratio;
      final lineNet = (origLine.netRevenueAmt as double) * ratio;
      // بناء بنود جديدة مع الحفاظ على baseQuantity
      final baseQty = (origLine.baseQuantity ?? origQty) * ratio;
      final newLine = origLine.copyWith(
        id: null,
        invoiceId: 0,
        quantity: retQty,
        baseQuantity: baseQty,
        amount: (lineAmount * 100).roundToDouble() / 100,
        totalAmount: ((lineAmount - lineDiscount) * 100).roundToDouble() / 100,
        discountAmt: (lineDiscount * 100).roundToDouble() / 100,
        taxAmt: (lineTax * 100).roundToDouble() / 100,
        otherFeeAmt: (lineOther * 100).roundToDouble() / 100,
        netRevenueAmt: (lineNet * 100).roundToDouble() / 100,
      );
      returnLines.add(newLine);
      retAmount += lineAmount;
      retDiscount += lineDiscount;
      retTax += lineTax;
      retOther += lineOther;
      retNet += lineNet;
    }
    if (returnLines.isEmpty) {
      AppToast.showError(context, 'لم يتم اختيار أي كمية للإرجاع');
      return;
    }
    // احتساب نسب الخصم والضريبة العامة الموزعة وزنياً مع كشف التكرار
    final grossParent = parent.amount;
    double headerDiscountShare = 0, headerTaxShare = 0, headerOtherShare = 0;
    if (grossParent > 0.005 && retAmount > 0) {
      final share = retAmount / grossParent;
      final sumParentLineDiscounts = parent.lines.fold<double>(0, (s, l) => s + (l.discountAmt ?? 0));
      double effectiveParentDiscount = parent.discountAmt ?? 0;
      if ((sumParentLineDiscounts - effectiveParentDiscount).abs() < 0.01 && sumParentLineDiscounts > 0.005) {
        effectiveParentDiscount = 0;
      }
      headerDiscountShare = effectiveParentDiscount * share;
      headerTaxShare = (parent.taxAmt ?? 0) * share;
      headerOtherShare = (parent.otherFeeAmt ?? 0) * share;
    }
    // حوّل الأرقام النهائية مع التقريب
    retDiscount += headerDiscountShare;
    retTax += headerTaxShare;
    retOther += headerOtherShare;
    retAmount = (retAmount * 100).roundToDouble() / 100;
    retDiscount = (retDiscount * 100).roundToDouble() / 100;
    retTax = (retTax * 100).roundToDouble() / 100;
    retOther = (retOther * 100).roundToDouble() / 100;
    final finalAmt = (retAmount - retDiscount + retOther + retTax);

    final now = DateTime.now();
    final returnNumber =
        'PR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';

    final typedLines = returnLines.cast<InvoiceLineEntity>();
    final invoiceForCreate = InvoiceEntity(
      invoiceType: InvoiceType.purchaseReturn.value,
      number: returnNumber,
      date: now.millisecondsSinceEpoch ~/ 1000,
      statement: parent.statement,
      amount: retAmount,
      totalAmount: retAmount,
      taxAmt: retTax,
      taxRatio: parent.taxRatio,
      discountAmt: retDiscount,
      discountRatio: parent.discountRatio,
      otherFeeAmt: retOther,
      otherFeeNetRatio: parent.otherFeeNetRatio,
      netRevenueAmt: (retAmount - retDiscount),
      finalAmt: (finalAmt * 100).roundToDouble() / 100,
      currencyId: parent.currencyId,
      stockId: parent.stockId,
      customerId: parent.customerId,
      taxId: parent.taxId,
      otherFeeAccountId: parent.otherFeeAccountId,
      invoiceTransType: parent.invoiceTransType,
      parentInvoiceId: parent.id,
      parentInvoiceNumber: parent.number,
      paymentStatus: 0,
      shippingAddress: parent.shippingAddress,
      dueDate: parent.dueDate,
      lines: typedLines,
    );

    if (parent.id == null) return;
    if (!context.mounted) return;
    context.read<PurchasesCubit>().createPurchaseReturn(
      invoiceForCreate,
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
              child: TextInputField(
                controller: _searchController,
                hint: 'بحث برقم الفاتورة...',
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
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

class _ReturnQtyDialog extends StatefulWidget {
  final InvoiceEntity parent;
  const _ReturnQtyDialog({required this.parent});
  @override
  State<_ReturnQtyDialog> createState() => _ReturnQtyDialogState();
}

class _ReturnQtyDialogState extends State<_ReturnQtyDialog> {
  late List<TextEditingController> _qtyCtrls;
  late List<double> _maxQty;

  @override
  void initState() {
    super.initState();
    _maxQty = widget.parent.lines.map((l) => (l.quantity as double)).toList();
    _qtyCtrls = _maxQty.map((q) => TextEditingController(text: q.toStringAsFixed(q.truncateToDouble() == q ? 0 : 2))).toList();
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('مردود للفاتورة ${widget.parent.number}', style: const TextStyle(fontSize: 14)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('حدد كميات الإرجاع لكل صنف (0 = عدم الإرجاع)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.parent.lines.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final line = widget.parent.lines[i];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('صنف #${line.categoryId ?? i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('الكمية الأصلية: ${_maxQty[i]}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('السعر: ${((line.amount / (line.quantity == 0 ? 1 : line.quantity))).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _qtyCtrls[i],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'مرتجع',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    for (int i = 0; i < _qtyCtrls.length; i++) {
                      _qtyCtrls[i].text = '0';
                    }
                    setState(() {});
                  },
                  child: const Text('تصفير الكل', style: TextStyle(fontSize: 11)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    for (int i = 0; i < _qtyCtrls.length; i++) {
                      _qtyCtrls[i].text = _maxQty[i].toStringAsFixed(_maxQty[i].truncateToDouble() == _maxQty[i] ? 0 : 2);
                    }
                    setState(() {});
                  },
                  child: const Text('تحديد الكل', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('إلغاء')),
        HasibButton(
          label: 'إنشاء المردود',
          onPressed: () {
            final result = <Map<String, dynamic>>[];
            for (int i = 0; i < widget.parent.lines.length; i++) {
              final txt = _qtyCtrls[i].text.trim();
              final q = double.tryParse(txt) ?? 0;
              if (q <= 0) continue;
              if (q - _maxQty[i] > 0.0001) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('كمية الصنف ${i + 1} تتجاوز الأصلية')));
                return;
              }
              result.add({'line': widget.parent.lines[i], 'qty': q});
            }
            if (result.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدد كمية واحدة على الأقل')));
              return;
            }
            Navigator.of(context).pop(result);
          },
          variant: HasibButtonVariant.danger,
          fullWidth: false,
        ),
      ],
    );
  }
}
