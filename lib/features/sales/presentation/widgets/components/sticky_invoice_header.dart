import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/amount_info_widget.dart';

class StickyInvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onCustomerTap;

  const StickyInvoiceHeader({
    super.key,
    required this.invoice,
    required this.onCustomerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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
                  Text(
                    invoice.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                      height: 1.4,
                    ),
                  ),
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
                        invoice.customer?.name ?? 'اختر العميل',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: AppColors.gray600,
                          height: 1.4,
                        ).copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormatter.formatDate(invoice.date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.gray600,
                  height: 1.4,
                ),
              ),
            ],
          ),
          if ((invoice.customer?.hasDebt ?? false) &&
              SettingsCache.showCustomerBalanceInInvoice) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تنبيه: العميل عليه مديونية بقيمة ${NumberFormatter.formatCurrency(invoice.customer!.balance.abs())}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.gray600,
                height: 1.4,
              ).copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                AmountInfoWidget(
                  label: 'الإجمالي',
                  amount: invoice.total,
                  color: AppColors.grey900,
                ),
                AmountInfoWidget(
                  label: 'المدفوع',
                  amount: invoice.paid,
                  color: AppColors.success,
                ),
                AmountInfoWidget(
                  label: 'المتبقي',
                  amount: invoice.remaining,
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
