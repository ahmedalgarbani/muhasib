import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';

class InventoryNotesCard extends StatelessWidget {
  final TextEditingController statementController;

  const InventoryNotesCard({
    super.key,
    required this.statementController,
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
                Icon(Icons.note, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: statementController,
              label: 'الملاحظات',
              hint: 'أدخل أي ملاحظات عن الجرد',
              prefixIcon: Icons.comment,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
