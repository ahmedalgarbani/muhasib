import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

/// Quotation Detail Page
/// Displays complete quotation information with convert and edit actions
class QuotationDetailPage extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailPage({
    Key? key,
    required this.quotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isConverted = quotation.nextInvoiceId != null && quotation.nextInvoiceId! > 0;
    final status = isConverted ? InvoiceStatus.converted : InvoiceStatus.open;

    return BlocListener<SalesCubit, SalesState>(
      listener: (context, state) {
        if (state is QuotationConverted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تحويل عرض السعر إلى فاتورة مبيعات بنجاح'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'عرض الفاتورة',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to the new invoice
                  // You can implement navigation to invoice detail page here
                },
              ),
            ),
          );
          // Pop back to the list after successful conversion
          Navigator.of(context).pop();
        } else if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gray50,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(status, isConverted),
              const SizedBox(height: 16),
              _buildCustomerCard(),
              const SizedBox(height: 16),
              _buildProductsCard(),
              const SizedBox(height: 16),
              _buildTotalsCard(),
              if (isConverted) ...[
                const SizedBox(height: 16),
                _buildConvertedInfoCard(),
              ],
            ],
          ),
        ),
        bottomNavigationBar: !isConverted
            ? _buildBottomActions(context)
            : null,
      ),
    );
  }

  Widget _buildHeaderCard(InvoiceStatus status, bool isConverted) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عرض سعر',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quotation.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == InvoiceStatus.converted
                        ? AppColors.purple100
                        : AppColors.blue100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status == InvoiceStatus.converted
                          ? AppColors.purple800
                          : AppColors.blue800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'التاريخ',
                    _formatDate(quotation.date),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'المستودع',
                    'مستودع #${quotation.stockId}',
                    Icons.warehouse,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات العميل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'العميل',
              'عميل #${quotation.customerId}',
              Icons.person,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'نوع الدفع',
              quotation.invoiceTransType == 0 ? 'نقدي' : 'آجل',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quotation.lines.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final line = quotation.lines[index];
                return _buildProductLine(line);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductLine(dynamic line) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Center(
            child: Icon(Icons.inventory_2, size: 20, color: AppColors.gray500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'منتج #${line.categoryId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الكمية: ${line.quantity} × ${_formatCurrency(line.unitPrice ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(line.totalPrice ?? (line.quantity * (line.unitPrice ?? 0))),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('المجموع الفرعي', quotation.amount),
            if (quotation.discountAmt != null && quotation.discountAmt! > 0) ...[
              const SizedBox(height: 12),
              _buildTotalRow('الخصم', quotation.discountAmt!, isDiscount: true),
            ],
            if (quotation.taxAmt != null && quotation.taxAmt! > 0) ...[
              const SizedBox(height: 12),
              _buildTotalRow('الضريبة', quotation.taxAmt!),
            ],
            const Divider(height: 24),
            _buildTotalRow(
              'الإجمالي النهائي',
              quotation.finalAmt ?? quotation.amount,
              isFinal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertedInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.purple100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.violet500, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.violet500, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'تم تحويل العرض',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'تم تحويل هذا العرض إلى فاتورة مبيعات رقم: ${quotation.nextInvoiceNumber}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.purple800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to sales invoice
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.violet500,
                side: const BorderSide(color: AppColors.violet500),
              ),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('عرض الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isDiscount = false, bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
            color: isFinal ? AppColors.gray900 : Colors.grey.shade700,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: isFinal ? 20 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
            color: isFinal
                ? AppColors.primary
                : isDiscount
                    ? AppColors.error
                    : AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            _showConvertDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          icon: const Icon(Icons.transform),
          label: const Text(
            'تحويل إلى فاتورة مبيعات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Generate proper invoice number with timestamp
              final now = DateTime.now();
              final invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
              
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
            icon: const Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            label: const Text('تأكيد التحويل'),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('تصدير PDF'),
              onTap: () {
                Navigator.pop(context);
                // Export to PDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة'),
              onTap: () {
                Navigator.pop(context);
                // Print
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ريال';
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
