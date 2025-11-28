import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';

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
                borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة للتقارير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: report.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

