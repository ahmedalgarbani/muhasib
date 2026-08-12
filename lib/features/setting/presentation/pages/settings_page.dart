import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
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
                _buildSettingCard(
                  context,
                  title: 'البيانات الشخصية',
                  subtitle: 'الاسم - العنوان - التوقيع - الشعار...',
                  icon: Icons.person_outline,
                  onTap: () => context.push(AppRoutes.settingsPersonal),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'إعدادات الطباعة',
                  subtitle: 'حجم الطباعة - خيارات ظهور البيانات الشخصية ...',
                  icon: Icons.print_outlined,
                  onTap: () => context.push(AppRoutes.settingsPrint),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'إعدادات الأمان',
                  subtitle: 'تفعيل كلمة المرور - كلمة المرور',
                  icon: Icons.security_outlined,
                  onTap: () => context.push(AppRoutes.settingsSecurity),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'إعدادات السندات',
                  subtitle: 'نوع العملة - الصيغ - التوقيع ...',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push(AppRoutes.settingsVoucher),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'إعدادات المخزون والفواتير',
                  subtitle: 'نوع العملة - التكلفة - خيارات ...',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.push(AppRoutes.settingsStock),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'صيانة النظام',
                  subtitle: 'فحص العمليات وإصلاحها ان وجدت مشكلة',
                  icon: Icons.build_outlined,
                  onTap: () => context.push(AppRoutes.settingsMaintenance),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'إعدادات أخرى',
                  subtitle: 'إعدادات التاريخ والوقت - إعدادات تكوينات النظام ...',
                  icon: Icons.settings_outlined,
                  onTap: () => context.push(AppRoutes.settingsOther),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  title: 'معالج الإعداد الأولي للنظام',
                  subtitle: 'إعداد اسم الشركة، العملة الرئيسية، والمخزن الافتراضي...',
                  icon: Icons.auto_fix_high_outlined,
                  onTap: () => context.push(AppRoutes.initialSetup),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
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

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
