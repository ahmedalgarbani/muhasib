import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

class InventoryActionButtons extends StatelessWidget {
  final bool isEmpty;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onPostInventory;

  const InventoryActionButtons({
    super.key,
    required this.isEmpty,
    required this.onSaveDraft,
    required this.onPostInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isEmpty ? null : onSaveDraft,
            icon: const Icon(Icons.save),
            label: const Text('حفظ كمسودة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HasibButton(
            label: 'ترحيل الجرد',
            onPressed: isEmpty ? null : onPostInventory,
            leading: const Icon(Icons.check),
            variant: HasibButtonVariant.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
