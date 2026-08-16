import 'package:flutter/material.dart';

enum CardType { primary, secondary, tertiary, success }

class CardData {
  final String title;
  final String balance;
  final String currency;
  final CardType type;
  final String? subtitle;
  final IconData? icon;

  const CardData({
    required this.title,
    required this.balance,
    this.currency = 'RY',
    this.type = CardType.primary,
    this.subtitle,
    this.icon,
  });

  List<Color> get gradientColors {
    switch (type) {
      case CardType.primary:
        return const [Color(0xFF006D74), Color(0xFF004B50)]; // Shamil Money Deep Teal
      case CardType.secondary:
        return const [Color(0xFF1E3A8A), Color(0xFF0F172A)]; // Royal Deep Blue
      case CardType.tertiary:
        return const [Color(0xFF047857), Color(0xFF064E3B)]; // Emerald Green
      case CardType.success:
        return const [Color(0xFF334155), Color(0xFF1E293B)]; // Dark Slate
    }
  }

  Color get accentColor {
    switch (type) {
      case CardType.primary:
        return const Color(0xFF4FD1C5);
      case CardType.secondary:
        return const Color(0xFF93C5FD);
      case CardType.tertiary:
        return const Color(0xFF6EE7B7);
      case CardType.success:
        return const Color(0xFF94A3B8);
    }
  }
}
