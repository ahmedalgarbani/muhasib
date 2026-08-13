import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'إعدادات الأمان'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                _buildCard([
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.key,
                      size: 20,
                      color: Colors.grey,
                    ),
                    title: const Text(
                      'طلب كلمة المرور عند الدخول',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    subtitle: Text(
                      isPasswordEnabled ? 'مفعل' : 'غير مفعل',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: isPasswordEnabled,
                    onChanged: (value) {
                      setState(() {
                        isPasswordEnabled = value;
                      });
                    },
                    activeThumbColor: Theme.of(context).primaryColor,
                    dense: true,
                  ),
                  if (isPasswordEnabled) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Colors.grey,
                      ),
                      title: const Text(
                        'كلمة المرور',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: TextInputField(
                        controller: passwordController,
                        hint: 'ادخل كلمة مرور جديدة',
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 24),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
