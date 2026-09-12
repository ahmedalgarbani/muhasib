import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/error_state_card.dart';

import '../../domain/entities/plan_entity.dart';
import '../../domain/plans_catalog.dart';
import '../cubit/plans_cubit.dart';
import '../cubit/plans_state.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_status_card.dart';
import '../widgets/support_whatsapp_card.dart';

/// Upgrade screen: compares every purchasable plan and points to activation.
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'الخطط والاشتراك', showBack: true),
      body: BlocBuilder<PlansCubit, PlansState>(
        builder: (context, state) {
          if (state is PlansLoading || state is PlansInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlansError) {
            return Center(
              child: ErrorStateCard(
                message: state.message,
                onRetry: () => context.read<PlansCubit>().refresh(),
              ),
            );
          }
          final loaded = state as PlansLoaded;
          return _PlansBody(state: loaded);
        },
      ),
    );
  }
}

class _PlansBody extends StatelessWidget {
  final PlansLoaded state;

  const _PlansBody({required this.state});

  void _selectPlan(BuildContext context, PlanEntity plan) {
    context.push(AppRoutes.settingsActivation, extra: plan.tier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        PlanStatusCard(
          state: state,
          onActivate: () =>
              context.push(AppRoutes.settingsActivation, extra: state.plan.tier),
        ),
        if (state.trial) ...[
          const SizedBox(height: 12),
          _Banner(
            icon: Icons.hourglass_top_outlined,
            color: AppColors.amber600,
            background: AppColors.amber50,
            text:
                'أنت في الفترة التجريبية — متبقي ${state.daysRemaining ?? 0} يوماً. '
                'رقّي خطتك قبل الانتهاء للحفاظ على كل المميزات.',
          ),
        ],
        if (state.expired) ...[
          const SizedBox(height: 12),
          const _Banner(
            icon: Icons.error_outline,
            color: AppColors.error,
            background: AppColors.errorLight,
            text:
                'انتهى اشتراكك وتم الرجوع للخطة المجانية. '
                'فعّل مفتاحاً جديداً لاستعادة المميزات المدفوعة.',
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'اختر الخطة المناسبة لك',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'جميع الأسعار بالريال السعودي، ويمكنك الترقية أو التخفيض في أي وقت.',
          style: TextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final plan in PlansCatalog.purchasablePlans)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PlanCard(
              plan: plan,
              state: state,
              onSelect: () => _selectPlan(context, plan),
            ),
          ),
        const SizedBox(height: 6),
        SupportWhatsAppCard(deviceId: state.deviceId),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
