import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseOrderCard extends StatelessWidget {
  final InvoiceEntity order;
  final VoidCallback? onTap;
  final VoidCallback onConvert;

  const PurchaseOrderCard({
    super.key,
    required this.order,
    this.onTap,
    required this.onConvert,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormatter.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isConverted = order.nextInvoiceId != null;

    return CustomCardContainer(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isConverted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm6),
                          ),
                          child: const Icon(
                            Icons.description,
                            size: 18,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب شراء #${order.number}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(order.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PurchaseOrderStatusChipWidget(isConverted: isConverted),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'المورد #${order.customerId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.inventory_2,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.lines.length} منتج',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'القيمة الإجمالية',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatCurrency(order.finalAmt ?? order.amount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isConverted)
                    HasibButton(
                      label: 'تحويل لفاتورة',
                      onPressed: onConvert,
                      leading: const Icon(Icons.transform, size: 16),
                      variant: HasibButtonVariant.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      fontSize: 12,
                    )
                  else
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: Text(
                        'الفاتورة #${order.nextInvoiceNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (order.statement != null && order.statement!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.statement!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PurchaseOrderStatusChipWidget extends StatelessWidget {
  final bool isConverted;

  const PurchaseOrderStatusChipWidget({
    super.key,
    required this.isConverted,
  });

  @override
  Widget build(BuildContext context) {
    if (isConverted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'تم التحويل',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'قيد الانتظار',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }
  }
}
