import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/accounts/presentation/pages/annual_close_page.dart';

class AnnualCloseYearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const AnnualCloseYearSelector({
    super.key,
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    padding: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Colors.grey[200]!),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.indigo500,
              borderRadius: BorderRadius.circular(AppRadius.sm14),
            ),
            child: const Icon(Icons.date_range, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السنة المالية',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$year',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
        ],
      ),
    ),
  );
}

class AnnualCloseSummaryCards extends StatelessWidget {
  const AnnualCloseSummaryCards({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: AnnualCloseSummaryCard(
          title: 'إجمالي الإيرادات',
          value: '0.00',
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: AnnualCloseSummaryCard(
          title: 'إجمالي المصروفات',
          value: '0.00',
          icon: Icons.trending_down,
          color: AppColors.error,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: AnnualCloseSummaryCard(
          title: 'صافي الربح/الخسارة',
          value: '0.00',
          icon: Icons.account_balance_wallet,
          color: AppColors.indigo500,
        ),
      ),
    ],
  );
}

class AnnualCloseSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AnnualCloseSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    padding: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Colors.grey[200]!),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class AnnualCloseStepsCard extends StatelessWidget {
  final List<AnnualCloseStep> steps;

  const AnnualCloseStepsCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    padding: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Colors.grey[200]!),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'خطوات الإقفال',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map(
            (entry) => AnnualCloseStepItem(
              step: entry.value,
              isLast: entry.key == steps.length - 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class AnnualCloseStepItem extends StatelessWidget {
  final AnnualCloseStep step;
  final bool isLast;

  const AnnualCloseStepItem({
    super.key,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = switch (step.status) {
      StepStatus.completed => (AppColors.success, Icons.check_circle),
      StepStatus.inProgress => (AppColors.indigo500, Icons.sync),
      StepStatus.error => (AppColors.error, Icons.error),
      StepStatus.pending => (Colors.grey, Icons.circle_outlined),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm10),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(step.icon, color: statusColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: statusColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(statusIcon, color: statusColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnnualCloseActionButtons extends StatelessWidget {
  final bool processing;
  final VoidCallback onPreview;
  final VoidCallback onStart;

  const AnnualCloseActionButtons({
    super.key,
    required this.processing,
    required this.onPreview,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.preview),
          label: const Text('معاينة'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            side: const BorderSide(color: AppColors.indigo500, width: 2),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: HasibButton(
          label: processing ? 'جاري الإقفال...' : 'بدء الإقفال',
          onPressed: processing ? null : onStart,
          leading: const Icon(Icons.play_arrow),
          loading: processing,
          variant: HasibButtonVariant.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ],
  );
}
