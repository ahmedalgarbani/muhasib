import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseFormProductsCard extends StatelessWidget {
  final List<InvoiceLineEntity> invoiceLines;
  final VoidCallback onAddLine;
  final ValueChanged<int> onEditLine;
  final ValueChanged<int> onDeleteLine;

  const PurchaseFormProductsCard({
    super.key,
    required this.invoiceLines,
    required this.onAddLine,
    required this.onEditLine,
    required this.onDeleteLine,
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
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المنتجات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'إضافة منتج',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invoiceLines.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد منتجات',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط على "إضافة منتج" للبدء',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoiceLines.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final line = invoiceLines[index];
                  final unitPrice = line.quantity == 0
                      ? 0.0
                      : (line.amount / line.quantity);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'المنتج #${line.groupId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'الكمية: ${line.quantity} × ${unitPrice.toStringAsFixed(2)} = ${line.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => onEditLine(index),
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => onDeleteLine(index),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
