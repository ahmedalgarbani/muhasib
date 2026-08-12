import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class CardButton extends StatelessWidget {
  final String label;

  const CardButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TextButton(
        onPressed: () {},
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
