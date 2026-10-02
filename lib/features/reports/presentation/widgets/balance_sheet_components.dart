import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/theme/app_color.dart';

class BalanceSheetEquationWidget extends StatelessWidget {
  final dynamic result;

  const BalanceSheetEquationWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final ok = result.isBalanced;
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: ok ? AppColors.emerald50 : AppColors.red50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ok ? AppColors.success : AppColors.error, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning,
            color: ok ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ok
                  ? 'الميزانية العمومية متوازنة تماماً ( الأصول = الخصوم + حقوق الملكية ) ✓'
                  : 'فرق الميزانية: ${result.difference.abs().toStringAsFixed(2)} ⚠',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ok ? AppColors.emerald800 : AppColors.red800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceSheetSectionWidget extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;
  final List<dynamic> rows;
  final String Function(double) formatCurrency;

  const BalanceSheetSectionWidget({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.rows,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      padding: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: AppConstant.defaultPadding,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(value),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: AppConstant.defaultPadding,
              child: Text(
                'لا توجد حسابات مسجلة في هذا البند',
                style: TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            )
          else
            ...rows.map(
              (r) => ListTile(
                dense: true,
                title: Text(
                  r.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  r.code,
                  style: TextStyle(fontSize: 11, color: AppColors.gray500),
                ),
                trailing: Text(
                  formatCurrency(r.displayAmount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
