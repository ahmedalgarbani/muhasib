import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

/// Shared label/value row used in detail sheets and cards.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  final Color? iconColor;
  final double? iconSize;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: effectiveIconColor, size: iconSize ?? 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colorScheme.outline),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: iconSize != null ? 14 : null,
              color: isBold ? AppColors.textPrimary : null,
            ),
          ),
        ],
      ),
    );
  }
}
