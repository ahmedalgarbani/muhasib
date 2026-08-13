import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/settings_navigation_card.dart';
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
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SettingsNavigationCard(
                  title: 'البيانات الشخصية',
                  subtitle: 'الاسم - العنوان - التوقيع - الشعار...',
                  icon: Icons.person_outline,
                  onTap: () => context.push(AppRoutes.settingsPersonal),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'إعدادات الطباعة',
                  subtitle: 'حجم الطباعة - خيارات ظهور البيانات الشخصية ...',
                  icon: Icons.print_outlined,
                  onTap: () => context.push(AppRoutes.settingsPrint),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'إعدادات الأمان',
                  subtitle: 'تفعيل كلمة المرور - كلمة المرور',
                  icon: Icons.security_outlined,
                  onTap: () => context.push(AppRoutes.settingsSecurity),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'إعدادات السندات',
                  subtitle: 'نوع العملة - الصيغ - التوقيع ...',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push(AppRoutes.settingsVoucher),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'إعدادات المخزون والفواتير',
                  subtitle: 'نوع العملة - التكلفة - خيارات ...',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.push(AppRoutes.settingsStock),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'صيانة النظام',
                  subtitle: 'فحص العمليات وإصلاحها ان وجدت مشكلة',
                  icon: Icons.build_outlined,
                  onTap: () => context.push(AppRoutes.settingsMaintenance),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'إعدادات أخرى',
                  subtitle:
                      'إعدادات التاريخ والوقت - إعدادات تكوينات النظام ...',
                  icon: Icons.settings_outlined,
                  onTap: () => context.push(AppRoutes.settingsOther),
                ),
                const SizedBox(height: 8),
                SettingsNavigationCard(
                  title: 'تفعيل التطبيق',
                  subtitle: 'الحصول على المميزات الكاملة للتطبيق',
                  icon: Icons.verified_outlined,
                  onTap: () => context.push(AppRoutes.settingsActivation),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
