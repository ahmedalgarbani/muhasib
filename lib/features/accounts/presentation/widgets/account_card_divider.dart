import 'package:flutter/material.dart';

/// Reusable divider for account cards
class AccountCardDivider extends StatelessWidget {
  final Color color;

  const AccountCardDivider({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color.withOpacity(0.3),
    );
  }
}
