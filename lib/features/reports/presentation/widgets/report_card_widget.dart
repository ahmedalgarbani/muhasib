import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';

class ReportCardWidget extends StatelessWidget {
  final ReportItem report;

  const ReportCardWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: () => context.push(report.route),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm14),
                ),
                child: Icon(report.icon, color: report.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.titleAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.descriptionAr,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: report.color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
