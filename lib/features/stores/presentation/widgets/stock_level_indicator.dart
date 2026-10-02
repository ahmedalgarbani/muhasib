import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

enum StockLevel { high, medium, low, out }

class StockLevelIndicator extends StatelessWidget {
  final double currentStock;
  final double? minStock;
  final double? maxStock;
  final bool showLabel;
  final bool showValue;
  final double? size;

  const StockLevelIndicator({
    super.key,
    required this.currentStock,
    this.minStock,
    this.maxStock,
    this.showLabel = true,
    this.showValue = true,
    this.size,
  });

  StockLevel get _stockLevel {
    if (currentStock <= 0) return StockLevel.out;
    if (minStock != null && currentStock <= minStock!) return StockLevel.low;
    if (maxStock != null && currentStock >= maxStock! * 0.8) return StockLevel.high;
    return StockLevel.medium;
  }

  Color get _color {
    switch (_stockLevel) {
      case StockLevel.high:
        return AppColors.success;
      case StockLevel.medium:
        return AppColors.warning;
      case StockLevel.low:
        return AppColors.error;
      case StockLevel.out:
        return AppColors.gray400;
    }
  }

  String get _label {
    switch (_stockLevel) {
      case StockLevel.high:
        return 'مخزون عالي';
      case StockLevel.medium:
        return 'مخزون متوسط';
      case StockLevel.low:
        return 'مخزون منخفض';
      case StockLevel.out:
        return 'نفذ المخزون';
    }
  }

  IconData get _icon {
    switch (_stockLevel) {
      case StockLevel.high:
        return Icons.trending_up;
      case StockLevel.medium:
        return Icons.trending_flat;
      case StockLevel.low:
        return Icons.trending_down;
      case StockLevel.out:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorSize = size ?? 24.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _color,
              width: 2,
            ),
          ),
          child: Icon(
            _icon,
            color: _color,
            size: indicatorSize * 0.6,
          ),
        ),
        if (showLabel || showValue) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel)
                Text(
                  _label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (showValue)
                Text(
                  '${currentStock.toStringAsFixed(0)} وحدة',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class StockLevelBar extends StatelessWidget {
  final double currentStock;
  final double maxStock;
  final double? minStock;
  final double height;
  final bool showPercentage;

  const StockLevelBar({
    super.key,
    required this.currentStock,
    required this.maxStock,
    this.minStock,
    this.height = 8,
    this.showPercentage = false,
  });

  double get _percentage => (currentStock / maxStock).clamp(0.0, 1.0);

  Color get _color {
    if (currentStock <= 0) return AppColors.gray400;
    if (minStock != null && currentStock <= minStock!) return AppColors.error;
    if (currentStock >= maxStock * 0.8) return AppColors.success;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: height,
              width: MediaQuery.of(context).size.width * _percentage,
              constraints: BoxConstraints(
                maxWidth: double.infinity,
              ),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            if (minStock != null)
              Positioned(
                left: (minStock! / maxStock) * MediaQuery.of(context).size.width,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: AppColors.error.withOpacity(0.5),
                ),
              ),
          ],
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(_percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
