import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

/// صفحة اختيار وحدة للصنف - تُستخدم بدل Dialog/BottomSheet
class UnitPickerPage extends StatelessWidget {
  final String productName;
  final List<ProductUnitOption> units;
  final double basePrice;
  final String currencySymbol;

  const UnitPickerPage({
    super.key,
    required this.productName,
    required this.units,
    required this.basePrice,
    this.currencySymbol = 'ر.س',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'اختر الوحدة'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCardContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('السعر الأساسي: ${NumberFormatter.formatNumber(basePrice)} $currencySymbol',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('الوحدات المتاحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...units.map((u) {
            // حساب السعر لهذه الوحدة
            final price = u.sellPrice ??
                (basePrice > 0
                    ? basePrice * u.totalConversion
                    : 0);
            final isMain = u.isMainUnit;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomCardContainer(
                onTap: () => Navigator.pop(context, u),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: u.isDefaultSale ? AppColors.primary.withValues(alpha: 0.4) : theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isMain ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isMain ? Icons.star : Icons.layers_outlined,
                          color: isMain ? AppColors.primary : Colors.grey.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(u.unitName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (u.isDefaultSale) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('افتراضي', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMain ? 'الوحدة الأساسية' : 'تحتوي على ${u.totalConversion.toStringAsFixed(u.totalConversion % 1 == 0 ? 0 : 2)} من الوحدة الأساسية',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (u.hasBarcode)
                            Text('باركود: ${u.barcode}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(NumberFormatter.formatNumber(price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                        Text(currencySymbol, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
