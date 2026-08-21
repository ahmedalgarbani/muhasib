import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/enums/approval_status.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class InvoiceReportSummaryCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const InvoiceReportSummaryCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 12),
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceReportStatusSummaryWidget extends StatelessWidget {
  final int withoutJournalEntry;

  const InvoiceReportStatusSummaryWidget({
    super.key,
    required this.withoutJournalEntry,
  });

  @override
  Widget build(BuildContext context) {
    final isClean = withoutJournalEntry == 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClean
            ? Colors.green.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isClean
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isClean ? Icons.check_circle : Icons.info,
            color: isClean ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            isClean
                ? 'جميع الفواتير تمت معالجتها برمجياً ومحاسبيًا.'
                : 'تنبيه: يوجد $withoutJournalEntry فواتير لم يُنشأ لها قيد محاسبي.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isClean ? Colors.green[800] : Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceReportBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;

  const InvoiceReportBadgeWidget({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class InvoiceReportCardWidget extends StatelessWidget {
  final dynamic row;
  final String formattedCurrency;

  const InvoiceReportCardWidget({
    super.key,
    required this.row,
    required this.formattedCurrency,
  });

  Color _getStatusColor(int status) {
    final s = ApprovalStatus.tryFromValue(status);
    return switch (s) {
      ApprovalStatus.approved => Colors.green,
      ApprovalStatus.pendingApproval => Colors.orange,
      ApprovalStatus.rejected => Colors.red,
      ApprovalStatus.converted => Colors.purple,
      ApprovalStatus.expired => Colors.grey,
      ApprovalStatus.draft => Colors.blueGrey,
      _ => Colors.grey,
    };
  }

  IconData _getStatusIcon(int status) {
    final s = ApprovalStatus.tryFromValue(status);
    return switch (s) {
      ApprovalStatus.approved => Icons.check_circle_outline,
      ApprovalStatus.pendingApproval => Icons.timelapse,
      ApprovalStatus.draft => Icons.mode_edit_outline,
      ApprovalStatus.rejected => Icons.cancel_outlined,
      ApprovalStatus.converted => Icons.transform,
      ApprovalStatus.expired => Icons.timer_off_outlined,
      _ => Icons.description_outlined,
    };
  }

  String _getStatusLabel(int status) {
    return ApprovalStatus.tryFromValue(status)?.labelAr ?? 'غير محدد';
  }

  @override
  Widget build(BuildContext context) {
    final r = row;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: AppConstant.defaultPadding,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(r.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _getStatusIcon(r.status),
            color: _getStatusColor(r.status),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              r.number.isNotEmpty ? r.number : '#${r.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              formattedCurrency,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(r.partyName, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(r.dateLabel, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InvoiceReportBadgeWidget(
                  label: _getStatusLabel(r.status),
                  color: _getStatusColor(r.status),
                ),
                const SizedBox(width: 8),
                InvoiceReportBadgeWidget(
                  label: r.hasJournalEntry ? 'مقيّدة' : 'بدون قيد',
                  color: r.hasJournalEntry ? Colors.teal : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
