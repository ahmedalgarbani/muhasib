import 'package:flutter/material.dart';

/// Reusable divider for account cards
class AccountCardDivider extends StatelessWidget {
  final Color color;

  const AccountCardDivider({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color.withOpacity(0.3),
    );
  }
}
