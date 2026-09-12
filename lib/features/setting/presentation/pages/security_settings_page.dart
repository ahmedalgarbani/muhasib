import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_switch_tile.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool isPasswordEnabled = false;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    final securityInfo = cubit.getSecurityInfo();

    isPasswordEnabled = securityInfo['isActive'] ?? false;
    final storedPassword = securityInfo['password']?.toString() ?? '';
    passwordController.text = storedPassword;
    confirmPasswordController.text = storedPassword;
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();

    final password = passwordController.text;
    if (isPasswordEnabled) {
      if (password.isEmpty) {
        AppToast.showError(context, 'يجب إدخال كلمة المرور لتفعيل القفل');
        return;
      }
      if (password != confirmPasswordController.text) {
        AppToast.showError(context, 'كلمتا المرور غير متطابقتين');
        return;
      }
    }

    final securityInfo = {
      'isActive': isPasswordEnabled,
      'password': isPasswordEnabled ? password : '',
    };

    await cubit.updateSetting('security_info', securityInfo);

    if (!mounted) return;
    if (!isPasswordEnabled) {
      passwordController.clear();
      confirmPasswordController.clear();
    }
    AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'إعدادات الأمان'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'التفعيل - كلمة المرور',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.key,
                      title: 'طلب كلمة المرور عند الدخول',
                      value: isPasswordEnabled,
                      onChanged: (value) {
                        setState(() {
                          isPasswordEnabled = value;
                        });
                      },
                    ),
                    if (isPasswordEnabled) ...[
                      const Divider(),
                      SettingsTextFieldTile(
                        icon: Icons.lock_outline,
                        title: 'كلمة المرور',
                        controller: passwordController,
                        hintText: 'ادخل كلمة مرور جديدة',
                        obscureText: _obscure,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        icon: Icons.lock_outline,
                        title: 'تأكيد كلمة المرور',
                        controller: confirmPasswordController,
                        hintText: 'أعد إدخال كلمة المرور',
                        obscureText: _obscure,
                      ),
                    ],
                  ],
                ),
                if (isPasswordEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'سيُطلب إدخال كلمة المرور عند فتح التطبيق وعند العودة إليه من الخلفية.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          child: Text(_obscure ? 'إظهار' : 'إخفاء'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                HasibButton(
                  label: 'حفظ التغييرات',
                  onPressed: _saveSettings,
                  variant: HasibButtonVariant.primary,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
