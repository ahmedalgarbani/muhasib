import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

import 'package:muhasib/features/sales/presentation/widgets/components/quotation_detail_components.dart';
import 'package:muhasib/core/constant/app_constant.dart';

/// Quotation Detail Page
/// Displays complete quotation information with convert and edit actions
class QuotationDetailPage extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailPage({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    final isConverted =
        quotation.nextInvoiceId != null && quotation.nextInvoiceId! > 0;
    final status = isConverted ? InvoiceStatus.converted : InvoiceStatus.open;

    return BlocListener<SalesCubit, SalesState>(
      listener: (context, state) {
        if (state is QuotationConverted) {
          AppToast.showSuccess(
            context,
            'تم تحويل عرض السعر إلى فاتورة مبيعات بنجاح',
          );
          Navigator.of(context).pop();
        } else if (state is SalesError) {
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: quotation.number,
          actions: [
            if (!isConverted)
              IconButton(
                onPressed: () {
                  // Navigate to edit form
                },
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل',
              ),
            IconButton(
              onPressed: () {
                _showPrintOptions(context);
              },
              icon: const Icon(Icons.print),
              tooltip: 'طباعة',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuotationDetailHeaderCard(quotation: quotation, status: status),
              const SizedBox(height: 16),
              QuotationDetailCustomerCard(quotation: quotation),
              const SizedBox(height: 16),
              QuotationDetailProductsCard(quotation: quotation),
              const SizedBox(height: 16),
              QuotationDetailTotalsCard(quotation: quotation),
              if (isConverted) ...[
                const SizedBox(height: 16),
                QuotationDetailConvertedInfoCard(quotation: quotation),
              ],
            ],
          ),
        ),
        bottomNavigationBar: !isConverted
            ? QuotationDetailBottomActions(
                onConvert: () {
                  _showConvertDialog(context);
                },
              )
            : null,
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: const Row(
          children: [
            Icon(Icons.transform, color: AppColors.success),
            SizedBox(width: 8),
            Text('تحويل عرض السعر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تحويل عرض السعر ${quotation.number} إلى فاتورة مبيعات؟',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم إنشاء فاتورة مبيعات جديدة بنفس البيانات',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'تأكيد التحويل',
            onPressed: () {
              Navigator.pop(dialogContext);

              // Generate proper invoice number with timestamp
              final now = DateTime.now();
              final invoiceNumber =
                  'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';

              // Create the sales invoice with all necessary data
              final salesInvoice = quotation.copyWith(
                id: null, // Clear ID so a new one is generated
                invoiceType: InvoiceType.salesInvoice.value,
                number: invoiceNumber,
                date: now.millisecondsSinceEpoch ~/ 1000,
                parentInvoiceId: quotation.id,
                parentInvoiceNumber: quotation.number,
                paymentStatus: 0, // Reset payment status
                nextInvoiceId: null,
                nextInvoiceType: null,
                nextInvoiceNumber: null,
              );

              // Trigger the conversion
              context.read<SalesCubit>().convertQuotation(
                quotation.id!,
                salesInvoice,
              );

              // Don't pop here, let the BlocListener handle navigation
            },
            leading: const Icon(Icons.check),
            variant: HasibButtonVariant.success,
          ),
        ],
      ),
    );
  }

  Future<List<List<String>>> _buildPrintRows() async {
    final productNames = <int, String>{};
    final result = await getIt<ProductRepository>().getProducts();
    result.fold((_) {}, (products) {
      for (final product in products) {
        if (product.id != null) productNames[product.id!] = product.name;
      }
    });

    final rows = <List<String>>[];
    final lines = quotation.lines;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final name = productNames[line.categoryId] ?? 'منتج #${line.categoryId}';
      rows.add([
        '${i + 1}',
        name,
        NumberFormatter.formatNumber(line.quantity),
        NumberFormatter.formatCurrency(line.amount),
        NumberFormatter.formatCurrency(line.totalAmount),
      ]);
    }
    rows.add([
      '',
      'الإجمالي',
      '',
      '',
      NumberFormatter.formatCurrency(quotation.finalAmt ?? quotation.amount),
    ]);
    return rows;
  }

  Future<void> _printDocument(
    BuildContext context, {
    required bool share,
  }) async {
    try {
      final rows = await _buildPrintRows();
      const headers = ['#', 'الصنف', 'الكمية', 'السعر', 'الإجمالي'];
      final title = 'عرض سعر ${quotation.number}';
      if (share) {
        await ExportService.sharePdf(
          title: title,
          headers: headers,
          data: rows,
          showInvoiceTerms: true,
        );
      } else {
        await ExportService.printData(
          title: title,
          headers: headers,
          data: rows,
          showInvoiceTerms: true,
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.showError(context, 'تعذر إنشاء المستند: $error');
      }
    }
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('تصدير PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                _printDocument(context, share: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة'),
              onTap: () {
                Navigator.pop(sheetContext);
                _printDocument(context, share: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to add copyWith
extension InvoiceEntityCopyWith on InvoiceEntity {
  InvoiceEntity copyWith({
    int? id,
    int? invoiceType,
    String? number,
    int? date,
    String? statement,
    double? amount,
    double? finalAmt,
    int? customerId,
    int? stockId,
    int? invoiceTransType,
    int? parentInvoiceId,
    String? parentInvoiceNumber,
    int? paymentStatus,
    int? nextInvoiceId,
    int? nextInvoiceType,
    String? nextInvoiceNumber,
    List<InvoiceLineEntity>? lines,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceType: invoiceType ?? this.invoiceType,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      amount: amount ?? this.amount,
      totalAmount: totalAmount,
      taxAmt: taxAmt,
      taxRatio: taxRatio,
      discountAmt: discountAmt,
      discountRatio: discountRatio,
      otherFeeAmt: otherFeeAmt,
      otherFeeNetRatio: otherFeeNetRatio,
      netRevenueAmt: netRevenueAmt,
      totalAmountAfterDiscount: totalAmountAfterDiscount,
      finalAmt: finalAmt ?? this.finalAmt,
      currencyId: currencyId,
      stockId: stockId ?? this.stockId,
      customerId: customerId ?? this.customerId,
      taxId: taxId,
      otherFeeAccountId: otherFeeAccountId,
      invoiceTransType: invoiceTransType ?? this.invoiceTransType,
      parentInvoiceId: parentInvoiceId ?? this.parentInvoiceId,
      parentInvoiceNumber: parentInvoiceNumber ?? this.parentInvoiceNumber,
      nextInvoiceType: nextInvoiceType ?? this.nextInvoiceType,
      nextInvoiceId: nextInvoiceId ?? this.nextInvoiceId,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      uNo: uNo,
      currencyCode: currencyCode,
      exchangeRate: exchangeRate,
      imagePath: imagePath,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingAddress: shippingAddress,
      dueDate: dueDate,
      lines: lines ?? this.lines,
    );
  }
}
