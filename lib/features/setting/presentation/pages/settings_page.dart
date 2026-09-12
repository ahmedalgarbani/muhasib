import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/error_state_card.dart';
import 'package:muhasib/core/widgets/settings_navigation_card.dart';
import 'package:muhasib/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:muhasib/features/plans/presentation/cubit/plans_state.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'الإعدادات'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsError) {
            return Center(
              child: ErrorStateCard(
                message: state.message,
                onRetry: () => context.read<SettingsCubit>().loadSettings(),
              ),
            );
          }
          return const _SettingsMenu();
        },
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'الحساب والبيانات'),
          SettingsNavigationCard(
            title: 'البيانات الشخصية',
            subtitle: 'الاسم - العنوان - التوقيع - الشعار',
            icon: Icons.person_outline,
            onTap: () => context.push(AppRoutes.settingsPersonal),
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'إعدادات الطباعة',
            subtitle: 'حجم الطباعة - خيارات ظهور البيانات الشخصية',
            icon: Icons.print_outlined,
            onTap: () => context.push(AppRoutes.settingsPrint),
          ),
          _sectionLabel(context, 'العمليات المالية'),
          SettingsNavigationCard(
            title: 'إعدادات السندات',
            subtitle: 'نوع العملة - الصيغ - التوقيع',
            icon: Icons.receipt_long_outlined,
            onTap: () => context.push(AppRoutes.settingsVoucher),
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'إعدادات المخزون والفواتير',
            subtitle: 'نوع العملة - التكلفة - خيارات العرض',
            icon: Icons.inventory_2_outlined,
            onTap: () => context.push(AppRoutes.settingsStock),
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'إعدادات نقاط البيع',
            subtitle: 'الدفع - الخصومات - الباركود - ائتمان العملاء',
            icon: Icons.point_of_sale_outlined,
            onTap: () => context.push(AppRoutes.settingsPos),
          ),
          _sectionLabel(context, 'النظام والأمان'),
          SettingsNavigationCard(
            title: 'إعدادات الأمان',
            subtitle: 'تفعيل كلمة المرور - كلمة المرور',
            icon: Icons.security_outlined,
            onTap: () => context.push(AppRoutes.settingsSecurity),
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'إعدادات أخرى',
            subtitle: 'إعدادات التاريخ والوقت - تكوينات النظام',
            icon: Icons.settings_outlined,
            onTap: () => context.push(AppRoutes.settingsOther),
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'صيانة النظام',
            subtitle: 'فحص العمليات وإصلاحها ان وجدت مشكلة',
            icon: Icons.build_outlined,
            badge: 'قريباً',
            onTap: () => context.push(AppRoutes.settingsMaintenance),
          ),
          _sectionLabel(context, 'الإعداد والتفعيل'),
          SettingsNavigationCard(
            title: 'معالج الإعداد الأولي للنظام',
            subtitle: 'إعداد اسم الشركة، العملة الرئيسية، والمخزن الافتراضي',
            icon: Icons.auto_fix_high_outlined,
            onTap: () => context.push(AppRoutes.initialSetup),
          ),
          const SizedBox(height: 10),
          BlocBuilder<PlansCubit, PlansState>(
            builder: (context, state) {
              final loaded = state is PlansLoaded ? state : null;
              return SettingsNavigationCard(
                title: 'تفعيل التطبيق',
                subtitle: _activationSubtitle(loaded),
                icon: Icons.verified_outlined,
                badge: loaded?.plan.nameAr,
                onTap: () => context.push(AppRoutes.settingsActivation),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingsNavigationCard(
            title: 'الخطط والترقية',
            subtitle: 'قارن بين الخطط واختر الأنسب لنشاطك',
            icon: Icons.workspace_premium_outlined,
            onTap: () => context.push(AppRoutes.plans),
          ),
        ],
      ),
    );
  }

  String _activationSubtitle(PlansLoaded? state) {
    if (state == null) return 'الحصول على المميزات الكاملة للتطبيق';
    if (state.expired) return 'انتهت الصلاحية — يلزم تجديد الترخيص';
    if (state.trial) {
      return 'فترة تجريبية — متبقي ${state.daysRemaining ?? 0} يوماً';
    }
    final license = state.license;
    if (license == null) return 'الحصول على المميزات الكاملة للتطبيق';
    if (license.isPerpetual) return 'ترخيص دائم مفعّل';
    final date = DateFormat('yyyy/MM/dd').format(license.expiresAt!);
    return 'سارية حتى $date';
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
