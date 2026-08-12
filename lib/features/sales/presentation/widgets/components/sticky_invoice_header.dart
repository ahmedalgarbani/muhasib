import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';

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
                  Text(invoice.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900, height: 1.4)),
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
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        invoice.customer?.name ?? 'ï؟½?ï؟½?ï؟½?ï؟½? ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('yyyy-MM-dd').format(invoice.date),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4),
              ),
            ],
          ),
          if (invoice.customer?.hasDebt ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ï؟½?ï؟½?ï؟½ï؟½ï؟½?ï؟½?: ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½? ï؟½?ï؟½?ï؟½?ï؟½? ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½? ${NumberFormatter.formatCurrency(invoice.customer!.balance.abs())}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4).copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountInfo(
                'ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?',
                invoice.total,
                AppColors.grey900,
              ),
              _buildAmountInfo(
                'ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?',
                invoice.paid,
                AppColors.success,
              ),
              _buildAmountInfo(
                'ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?ï؟½?',
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.gray600, height: 1.4)),
        Text(
          NumberFormatter.formatNumber(amount),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.gray900, height: 1.5).copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
