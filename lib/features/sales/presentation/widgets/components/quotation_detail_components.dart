import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat('yyyy-MM-dd', 'ar').format(date);
}

String _formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'ar');
  return '${formatter.format(amount)} ريال';
}

class QuotationDetailHeaderCard extends StatelessWidget {
  final InvoiceEntity quotation;
  final InvoiceStatus status;

  const QuotationDetailHeaderCard({
    super.key,
    required this.quotation,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                  child: _QuotationInfoItem(
                    label: 'التاريخ',
                    value: _formatDate(quotation.date),
                    icon: Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _QuotationInfoItem(
                    label: 'المستودع',
                    value: 'مستودع #${quotation.stockId}',
                    icon: Icons.warehouse,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuotationDetailCustomerCard extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailCustomerCard({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
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
            _QuotationInfoItem(
              label: 'العميل',
              value: 'عميل #${quotation.customerId}',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _QuotationInfoItem(
              label: 'نوع الدفع',
              value: quotation.invoiceTransType == 0 ? 'نقدي' : 'آجل',
              icon: Icons.payment,
            ),
          ],
        ),
      ),
    );
  }
}

class QuotationDetailProductsCard extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailProductsCard({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
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
                return _QuotationProductLineWidget(line: line);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotationProductLineWidget extends StatelessWidget {
  final dynamic line;

  const _QuotationProductLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(
            line.totalPrice ?? (line.quantity * (line.unitPrice ?? 0)),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

class QuotationDetailTotalsCard extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailTotalsCard({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _QuotationTotalRow(label: 'المجموع الفرعي', amount: quotation.amount),
            if (quotation.discountAmt != null &&
                quotation.discountAmt! > 0) ...[
              const SizedBox(height: 12),
              _QuotationTotalRow(
                label: 'الخصم',
                amount: quotation.discountAmt!,
                isDiscount: true,
              ),
            ],
            if (quotation.taxAmt != null && quotation.taxAmt! > 0) ...[
              const SizedBox(height: 12),
              _QuotationTotalRow(label: 'الضريبة', amount: quotation.taxAmt!),
            ],
            const Divider(height: 24),
            _QuotationTotalRow(
              label: 'الإجمالي النهائي',
              amount: quotation.finalAmt ?? quotation.amount,
              isFinal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class QuotationDetailConvertedInfoCard extends StatelessWidget {
  final InvoiceEntity quotation;

  const QuotationDetailConvertedInfoCard({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
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
                const Icon(
                  Icons.check_circle,
                  color: AppColors.violet500,
                  size: 24,
                ),
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
              style: const TextStyle(fontSize: 14, color: AppColors.purple800),
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
}

class QuotationDetailBottomActions extends StatelessWidget {
  final VoidCallback onConvert;

  const QuotationDetailBottomActions({super.key, required this.onConvert});

  @override
  Widget build(BuildContext context) {
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
        child: HasibButton(
          label: 'تحويل إلى فاتورة مبيعات',
          onPressed: onConvert,
          leading: const Icon(Icons.transform),
          variant: HasibButtonVariant.success,
          padding: const EdgeInsets.symmetric(vertical: 16),
          fontSize: 16,
        ),
      ),
    );
  }
}

class _QuotationInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuotationInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
}

class _QuotationTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;
  final bool isFinal;

  const _QuotationTotalRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) {
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
}
