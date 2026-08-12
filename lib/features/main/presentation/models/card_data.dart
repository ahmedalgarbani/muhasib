import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

enum CardType { primary, secondary, tertiary, success }

class CardData {
  final String title;
  final String balance;
  final CardType type;

  CardData(this.title, this.balance, this.type);

  Color get backgroundColor {
    switch (type) {
      case CardType.primary:
        return AppColors.materialDeepOrange500;
      case CardType.secondary:
        return AppColors.materialPurple500;
      case CardType.tertiary:
        return AppColors.materialBlue700;
      case CardType.success:
        return AppColors.materialTeal600;
    }
  }
}
