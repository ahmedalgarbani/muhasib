import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({Key? key}) : super(key: key);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'إعدادات الأمان',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
                    secondary: const Icon(Icons.key, size: 20, color: Colors.grey),
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
                    activeColor: Theme.of(context).primaryColor,
                    dense: true,
                  ),
                  if (isPasswordEnabled) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                      title: const Text(
                        'كلمة المرور',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'ادخل كلمة مرور جديدة',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
        borderRadius: BorderRadius.circular(12),
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
