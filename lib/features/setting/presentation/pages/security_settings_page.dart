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
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    final securityInfo = cubit.getSecurityInfo();

    isPasswordEnabled = securityInfo['isActive'] ?? false;
    passwordController.text = securityInfo['password'] ?? '';
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final securityInfo = {
      'isActive': isPasswordEnabled,
      'password': passwordController.text,
    };

    await cubit.updateSetting('security_info', securityInfo);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ الإعدادات بنجاح');
    }
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
                        obscureText: true,
                      ),
                    ],
                  ],
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
