import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';

class PurchaseDetailProductsList extends StatelessWidget {
  final List<InvoiceLineEntity> lines;

  const PurchaseDetailProductsList({
    super.key,
    required this.lines,
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
                  'الأصناف المشتراة',
                  style: TextStyle(
                    fontSize: 14,
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '${lines.length} صنف',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lines.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'لا توجد أصناف في هذه الفاتورة',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  final List<ProductEntity> products = switch (state) {
                    ProductsLoaded(products: final p) => p,
                    _ => const <ProductEntity>[],
                  };

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lines.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final catId = line.categoryId ?? line.groupId;
                      final foundProduct =
                          products.where((p) => p.id == catId);
                      final productName = foundProduct.isNotEmpty
                          ? (foundProduct.first.barcodeNo.isNotEmpty
                              ? '${foundProduct.first.name} (${foundProduct.first.barcodeNo})'
                              : foundProduct.first.name)
                          : null;

                      return PurchaseProductItemWidget(
                        line: line,
                        index: index + 1,
                        productName: productName,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class PurchaseProductItemWidget extends StatelessWidget {
  final InvoiceLineEntity line;
  final int index;
  final String? productName;

  const PurchaseProductItemWidget({
    super.key,
    required this.line,
    required this.index,
    this.productName,
  });

  String _formatCurrency(double amount) {
    return NumberFormatter.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice =
        line.quantity > 0 ? line.amount / line.quantity : 0.0;
    final displayName = productName ??
        'الصنف #${line.categoryId ?? line.groupId ?? index}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'الكمية: ${line.quantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'السعر: ${_formatCurrency(unitPrice)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(line.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (line.discountAmt != null && line.discountAmt! > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'خصم: ${_formatCurrency(line.discountAmt!)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
