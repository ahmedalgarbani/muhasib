import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

class InventoryProductCountCard extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onScanBarcode;
  final VoidCallback onAddProduct;

  const InventoryProductCountCard({
    super.key,
    required this.searchController,
    required this.onScanBarcode,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomCardContainer(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'إضافة منتج للجرد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: searchController,
                    label: 'البحث عن منتج',
                    hint: 'اسم المنتج أو الباركود',
                    prefixIcon: Icons.search,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: onScanBarcode,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                HasibButton(
                  label: 'إضافة',
                  onPressed: onAddProduct,
                  leading: const Icon(Icons.add),
                  variant: HasibButtonVariant.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
