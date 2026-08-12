import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class CardHeader extends StatelessWidget {
  final String title;

  const CardHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 5,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}