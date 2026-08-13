import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class ReportKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trendText;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const ReportKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trendText,
    this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              if (subtitle != null || trendText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trendText != null) ...[
                      Icon(
                        isPositiveTrend == true
                            ? Icons.trending_up
                            : (isPositiveTrend == false
                                  ? Icons.trending_down
                                  : Icons.remove),
                        size: 14,
                        color: isPositiveTrend == true
                            ? Colors.green[700]
                            : (isPositiveTrend == false
                                  ? Colors.red[700]
                                  : Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositiveTrend == true
                              ? Colors.green[700]
                              : (isPositiveTrend == false
                                    ? Colors.red[700]
                                    : Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
