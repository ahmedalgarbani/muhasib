import 'package:flutter/material.dart';

class CardBalance extends StatelessWidget {
  final String balance;
  final bool showBalance;

  const CardBalance({
    Key? key,
    required this.balance,
    required this.showBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'الرصيد',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          showBalance ? balance : '*******',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
