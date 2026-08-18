
import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const AppBarIcon({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

