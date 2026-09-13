import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/domain/templates/sales_accounting_template.dart';
import 'package:muhasib/features/sales/presentation/widgets/constants/invoice_ui_constants.dart';
import 'package:muhasib/core/constant/app_constant.dart';

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat('yyyy-MM-dd', 'ar').format(date);
}

String _formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'ar');
  return '${formatter.format(amount)} ريال';
}

class ReturnDetailHeaderCard extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailHeaderCard({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
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
                      'فاتورة مرتجع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      returnInvoice.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                InvoiceTypeBadge(type: InvoiceType.salesReturn),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ReturnInfoItem(
                    label: 'تاريخ المرتجع',
                    value: _formatDate(returnInvoice.date),
                    icon: Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _ReturnInfoItem(
                    label: 'المستودع',
                    value: 'مستودع #${returnInvoice.stockId}',
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

class ReturnDetailOriginalInvoiceCard extends StatelessWidget {
  final InvoiceEntity returnInvoice;
  final VoidCallback? onViewOriginal;

  const ReturnDetailOriginalInvoiceCard({
    super.key,
    required this.returnInvoice,
    this.onViewOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      color: AppColors.amber100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.warning, width: 2),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.amber800,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'الفاتورة الأصلية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'رقم الفاتورة: ${returnInvoice.parentInvoiceNumber ?? "غير محدد"}',
              style: const TextStyle(fontSize: 14, color: AppColors.amber800),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onViewOriginal,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber800,
                side: const BorderSide(color: AppColors.amber800),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('عرض الفاتورة الأصلية'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReturnDetailCustomerCard extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailCustomerCard({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
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
            _ReturnInfoItem(
              label: 'العميل',
              value: 'عميل #${returnInvoice.customerId}',
              icon: Icons.person,
            ),
          ],
        ),
      ),
    );
  }
}

class ReturnDetailProductsCard extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailProductsCard({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المنتجات المرتجعة',
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
              itemCount: returnInvoice.lines.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final line = returnInvoice.lines[index];
                return _ReturnProductLineWidget(line: line);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnProductLineWidget extends StatelessWidget {
  final dynamic line;

  const _ReturnProductLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Center(
            child: Icon(
              Icons.assignment_return,
              size: 20,
              color: AppColors.error,
            ),
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
                'الكمية المرتجعة: ${line.quantity} × ${_formatCurrency(line.amount)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(line.totalAmount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class ReturnDetailTotalsCard extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailTotalsCard({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          children: [
            _ReturnTotalRow(label: 'المجموع الفرعي', amount: returnInvoice.amount),
            if (returnInvoice.discountAmt != null &&
                returnInvoice.discountAmt! > 0) ...[
              const SizedBox(height: 12),
              _ReturnTotalRow(
                label: 'الخصم',
                amount: -returnInvoice.discountAmt!,
              ),
            ],
            if (returnInvoice.taxAmt != null && returnInvoice.taxAmt! > 0) ...[
              const SizedBox(height: 12),
              _ReturnTotalRow(label: 'الضريبة', amount: returnInvoice.taxAmt!),
            ],
            const Divider(height: 24),
            _ReturnTotalRow(
              label: 'إجمالي المرتجع',
              amount: returnInvoice.finalAmt ?? returnInvoice.amount,
              isFinal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ReturnDetailAccountingCard extends StatelessWidget {
  final Future<Map<String, dynamic>> entriesFuture;

  const ReturnDetailAccountingCard({super.key, required this.entriesFuture});

  @override
  Widget build(BuildContext context) {
    final template = SalesAccountingTemplate();

    return FutureBuilder<Map<String, dynamic>>(
      future: entriesFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'entries': <Map<String, dynamic>>[],
              'total_debit': 0.0,
              'total_credit': 0.0,
            };

        final isBalanced = template.validateEntries(data);
        final entries = data['entries'] as List;

        return CustomCardContainer(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'القيود المحاسبية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isBalanced
                            ? AppColors.emerald100
                            : AppColors.red100,
                        borderRadius: BorderRadius.circular(AppRadius.sm6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBalanced ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: isBalanced
                                ? AppColors.emerald800
                                : AppColors.red800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBalanced ? 'متوازن' : 'غير متوازن',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBalanced
                                  ? AppColors.emerald800
                                  : AppColors.red800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...entries.map((entry) {
                        final debit = entry['debit'] as double;
                        final credit = entry['credit'] as double;
                        final accountName = entry['account_name'] as String;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  debit > 0
                                      ? 'من ح/ $accountName'
                                      : 'إلى ح/ $accountName',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Text(
                                _formatCurrency(debit > 0 ? debit : credit),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: debit > 0
                                      ? AppColors.emerald600
                                      : AppColors.red600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجماليات:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'مدين: ${_formatCurrency(data['total_debit'] as double)} | دائن: ${_formatCurrency(data['total_credit'] as double)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReturnInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReturnInfoItem({
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

class _ReturnTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isFinal;

  const _ReturnTotalRow({
    required this.label,
    required this.amount,
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
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isFinal ? 20 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}
