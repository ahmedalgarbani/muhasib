import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/route/safe_pop.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class GenericReportPage extends StatelessWidget {
  final ReportItem report;

  const GenericReportPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: report.titleAr,
      icon: report.icon,
      color: report.color,
      reportBuilder: (filter) => _GenericReportContent(report: report),
    );
  }
}

class _GenericReportContent extends StatelessWidget {
  final ReportItem report;

  const _GenericReportContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: report.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                report.icon,
                size: 64,
                color: report.color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              report.titleAr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              report.descriptionAr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: AppConstant.defaultPadding,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.engineering, color: Colors.amber, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'هذا التقرير قيد التطوير',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            HasibButton(
              label: 'العودة للتقارير',
              onPressed: () => context.safePop(null, AppRoutes.reports),
              leading: const Icon(Icons.arrow_back),
              variant: HasibButtonVariant.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ],
        ),
      ),
    );
  }
}

