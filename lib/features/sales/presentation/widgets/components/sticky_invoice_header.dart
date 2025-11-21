import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:intl/intl.dart';

class StickyInvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onCustomerTap;

  const StickyInvoiceHeader({
    Key? key,
    required this.invoice,
    required this.onCustomerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.grey200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(invoice.number, style: AppTextStyles.title),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: onCustomerTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invoice.customer?.name ?? '�?�?�?�? �?�?�?�?�?�?',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('yyyy-MM-dd').format(invoice.date),
                style: AppTextStyles.small,
              ),
            ],
          ),
          if (invoice.customer?.hasDebt ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '�?�?���?�?: �?�?�?�?�?�? �?�?�?�? �?�?�?�?�?�?�? ${NumberFormatter.formatCurrency(invoice.customer!.balance.abs())}',
              style: AppTextStyles.small.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountInfo(
                '�?�?�?�?�?�?�?�?',
                invoice.total,
                AppColors.grey900,
              ),
              _buildAmountInfo(
                '�?�?�?�?�?�?�?',
                invoice.paid,
                AppColors.success,
              ),
              _buildAmountInfo(
                '�?�?�?�?�?�?�?',
                invoice.remaining,
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        Text(
          NumberFormatter.formatNumber(amount),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
