import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_feature.dart';
import '../../domain/entities/plan_limit.dart';
import '../../domain/entities/plan_tier.dart';
import '../../domain/plans_catalog.dart';
import '../cubit/plans_state.dart';
import 'plan_ui.dart';

/// Pricing/entitlements card for a single purchasable plan.
class PlanCard extends StatelessWidget {
  final PlanEntity plan;
  final PlansLoaded state;
  final VoidCallback onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    required this.state,
    required this.onSelect,
  });

  bool get _isCurrent => state.plan.tier == plan.tier && !state.expired;

  PlanEntity? get _previousPlan {
    final index = PlansCatalog.purchasablePlans.indexOf(plan);
    if (index <= 0) return null;
    return PlansCatalog.purchasablePlans[index - 1];
  }

  List<PlanFeature> get _highlightedFeatures {
    final previous = _previousPlan;
    final features = previous == null
        ? plan.features
        : plan.features.difference(previous.features);
    return PlanFeature.values.where(features.contains).toList();
  }

  String get _ctaLabel {
    if (_isCurrent) return 'خطتك الحالية';
    if (plan.tier == PlanTier.free) return 'الرجوع إلى المجانية';
    if (plan.tier.rank > state.plan.tier.rank) {
      return 'ترقية إلى ${plan.nameAr}';
    }
    return 'تغيير إلى ${plan.nameAr}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = plan.tier.color;
    final highlights = _highlightedFeatures;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _isCurrent
              ? color
              : plan.isPopular
                  ? color.withValues(alpha: 0.6)
                  : theme.dividerColor,
          width: _isCurrent || plan.isPopular ? 1.6 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg - 1),
                  topRight: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: const Text(
                'الأكثر شعبية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(plan.tier.icon, color: color, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.nameAr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isCurrent) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            plan.taglineAr,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PriceBlock(plan: plan, color: color),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 12),
                if (_previousPlan != null) ...[
                  Text(
                    'كل مميزات الخطة ${_previousPlan!.nameAr}، بالإضافة إلى:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...highlights.take(7).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 17,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature.labelAr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (highlights.length > 7)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7, right: 25),
                    child: Text(
                      '+ ${highlights.length - 7} مميزات أخرى',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PlanLimit.maxProducts,
                    PlanLimit.maxWarehouses,
                    PlanLimit.maxUsers,
                    PlanLimit.maxCurrencies,
                  ]
                      .map(
                        (limit) => _LimitChip(
                          label: limit.labelAr,
                          value: plan.limitLabel(limit),
                          color: color,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                HasibButton(
                  label: _ctaLabel,
                  onPressed: _isCurrent ? null : onSelect,
                  variant: plan.isPopular
                      ? HasibButtonVariant.primary
                      : HasibButtonVariant.secondary,
                  icon: _isCurrent ? null : Icons.arrow_upward_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final PlanEntity plan;
  final Color color;

  const _PriceBlock({required this.plan, required this.color});

  @override
  Widget build(BuildContext context) {
    final monthly = plan.priceMonthly;
    if (monthly == null) {
      return const SizedBox.shrink();
    }
    if (monthly == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Text(
          'مجاناً',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.emerald700,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$monthly',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Text('ر.س/شهر', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        if (plan.priceYearly != null)
          Text(
            'أو ${plan.priceYearly} ر.س سنوياً',
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _LimitChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LimitChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
