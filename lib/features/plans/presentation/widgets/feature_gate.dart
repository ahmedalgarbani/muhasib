import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

import '../../domain/entities/plan_feature.dart';
import '../cubit/plans_cubit.dart';
import '../cubit/plans_state.dart';
import 'plan_ui.dart';

/// Shows [child] only when the active plan includes [feature]; otherwise
/// renders [LockedFeaturePage] with an upgrade call to action.
class FeatureGate extends StatelessWidget {
  final PlanFeature feature;
  final Widget child;

  const FeatureGate({super.key, required this.feature, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansCubit, PlansState>(
      builder: (context, state) {
        final allowed = state is PlansLoaded
            ? state.plan.hasFeature(feature) && !state.expired
            : true;
        return allowed ? child : LockedFeaturePage(feature: feature);
      },
    );
  }
}

/// Full-page lock screen used by [FeatureGate] and reachable from the router.
class LockedFeaturePage extends StatelessWidget {
  final PlanFeature feature;

  const LockedFeaturePage({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minimumTier = feature.minimumTier;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'ميزة مقفلة', showBack: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: AppColors.amber700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'هذه الميزة غير متاحة في خطتك الحالية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feature.labelAr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (minimumTier != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: minimumTier.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl28),
                  ),
                  child: Text(
                    'متاحة بدءاً من الخطة ${minimumTier.nameAr}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: minimumTier.color,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              HasibButton(
                label: 'عرض الخطط والترقية',
                icon: Icons.workspace_premium_outlined,
                onPressed: () => context.push(AppRoutes.plans),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
