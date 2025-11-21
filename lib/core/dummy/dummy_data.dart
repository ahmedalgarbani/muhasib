import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';

enum CardType { primary, secondary, tertiary, success }

class CardData {
  final String title;
  final String balance;
  final CardType type;

  CardData(this.title, this.balance, this.type);

  LinearGradient get gradient {
    switch (type) {
      case CardType.primary:
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardType.secondary:
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardType.tertiary:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CardType.success:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
