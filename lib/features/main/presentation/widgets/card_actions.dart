import 'package:flutter/material.dart';

class CardActions extends StatelessWidget {
  final bool showBalance;
  final VoidCallback onToggleBalance;

  const CardActions({
    Key? key,
    required this.showBalance,
    required this.onToggleBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              showBalance ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: onToggleBalance,
          ),
        ),
        Row(
          children: const [
            Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'صندوق',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
