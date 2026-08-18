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
    this.currency = 'YER',
    this.type = CardType.primary,
    this.subtitle,
    this.icon,
  });

  List<Color> get gradientColors {
    switch (type) {
      case CardType.primary:
        return const [
          Color(0xFF006C35),
          Color(0xFF004D25),
        ]; // Saudi Royal Emerald
      case CardType.secondary:
        return const [
          Color(0xFF0F2E22),
          Color(0xFF061C14),
        ]; // Deep Forest Emerald
      case CardType.tertiary:
        return const [Color(0xFF1E293B), Color(0xFF0F172A)]; // Sleek Tech Slate
      case CardType.success:
        return const [
          Color(0xFF059669),
          Color(0xFF047857),
        ]; // Vibrant Saudi Mint-Emerald
    }
  }

  Color get accentColor {
    switch (type) {
      case CardType.primary:
        return const Color(0xFF6EE7B7);
      case CardType.secondary:
        return const Color(0xFFA7F3D0);
      case CardType.tertiary:
        return const Color(0xFF94A3B8);
      case CardType.success:
        return const Color(0xFFD1FAE5);
    }
  }
}
