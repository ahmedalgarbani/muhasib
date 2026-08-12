import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

class PrintSettingsPage extends StatefulWidget {
  const PrintSettingsPage({super.key});

  @override
  State<PrintSettingsPage> createState() => _PrintSettingsPageState();
}

class _PrintSettingsPageState extends State<PrintSettingsPage> {
  // Print Settings Variables
  String _printType = 'A4';
  String _printMethod = 'Pdf';
  String _printSize = 'A4';
  String _connectionType = 'عبر وسيط آخر';
  
  // Toggles
  bool _showHeaderData = true;
  bool _showCompanyName = true;
  bool _showCompanyAddress = true;
  bool _showCompanyPhone = true;
  bool _showDate = false;
  bool _showTime = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();
    
    setState(() {
      _printType = _getPrintTypeString(printerInfo['printType'] ?? 1);
      _printMethod = _getPrintMethodString(printerInfo['printSize'] ?? 0);
      _printSize = printerInfo['print_paper_size'] ?? 'A4';
      _connectionType = _getConnectionTypeString(printerInfo['printerConnect'] ?? 1);
      
      _showHeaderData = printerInfo['showHeaderData'] ?? true;
      _showCompanyName = printerInfo['showHeaderCompanyName'] ?? true;
      _showCompanyAddress = printerInfo['showHeaderCompanyAddress'] ?? true;
      _showCompanyPhone = printerInfo['showHeaderCompanyPhone'] ?? true;
      _showDate = printerInfo['showDate'] ?? false;
      _showTime = printerInfo['showTime'] ?? false;
    });
  }

  String _getPrintTypeString(int type) {
    switch (type) {
      case 0: return 'A5';
      case 1: return 'A4';
      case 2: return 'Letter';
      default: return 'A4';
    }
  }

  String _getPrintMethodString(int method) {
    switch (method) {
      case 0: return 'Pdf';
      case 1: return 'Html';
      default: return 'Pdf';
    }
  }

  String _getConnectionTypeString(int type) {
    switch (type) {
      case 0: return 'غير وسيط آخر';
      case 1: return 'عبر وسيط آخر';
      default: return 'عبر وسيط آخر';
    }
  }

  int _getPrintTypeInt(String type) {
    switch (type) {
      case 'A5': return 0;
      case 'A4': return 1;
      case 'Letter': return 2;
      default: return 1;
    }
  }

  int _getPrintMethodInt(String method) {
    switch (method) {
      case 'Pdf': return 0;
      case 'Html': return 1;
      default: return 0;
    }
  }

  int _getConnectionTypeInt(String type) {
    switch (type) {
      case 'غير وسيط آخر': return 0;
      case 'عبر وسيط آخر': return 1;
      default: return 1;
    }
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final printerInfo = cubit.getPrinterInfo();
    
    final updatedInfo = {
      ...printerInfo,
      'printType': _getPrintTypeInt(_printType),
      'printSize': _getPrintMethodInt(_printMethod),
      'print_paper_size': _printSize,
      'printerConnect': _getConnectionTypeInt(_connectionType),
      'showHeaderData': _showHeaderData,
      'showHeaderCompanyName': _showCompanyName,
      'showHeaderCompanyAddress': _showCompanyAddress,
      'showHeaderCompanyPhone': _showCompanyPhone,
      'showDate': _showDate,
      'showTime': _showTime,
    };
    
    await cubit.updateSetting('printer_info', updatedInfo);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: CustomAppBar(title: 'إعدادات الطباعة'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: الإعدادات الرئيسية
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                  child: Text(
                    'الإعدادات الرئيسية',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      _buildDropdownTile(
                        icon: Icons.description_outlined,
                        label: 'نوع الخط في الطباعة',
                        subtitle: 'الخط الثاني (الكبير)',
                        value: _printType,
                        items: ['A4', 'A5', 'Letter'],
                        onChanged: (value) => setState(() => _printType = value!),
                      ),
                      _buildDropdownTile(
                        icon: Icons.print_outlined,
                        label: 'طريقة الطباعة',
                        subtitle: _printMethod,
                        value: _printMethod,
                        items: ['Pdf', 'Html'],
                        onChanged: (value) => setState(() => _printMethod = value!),
                      ),
                      _buildDropdownTile(
                        icon: Icons.photo_size_select_large_outlined,
                        label: 'حجم الطباعة',
                        subtitle: _printSize,
                        value: _printSize,
                        items: ['A4', 'A5', 'Letter'],
                        onChanged: (value) => setState(() => _printSize = value!),
                      ),
                      _buildDropdownTile(
                        icon: Icons.link_outlined,
                        label: 'نوع اتصال الطابعة',
                        subtitle: _connectionType,
                        value: _connectionType,
                        items: ['عبر وسيط آخر', 'غير وسيط آخر'],
                        onChanged: (value) => setState(() => _connectionType = value!),
                      ),
                    ],
                  ),
                ),

                // Section: إعدادات البيانات
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
                  child: Text(
                    'إعدادات البيانات',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.article_outlined,
                        label: 'عرض بيانات رأس الصفحة',
                        value: _showHeaderData,
                        onChanged: (value) => setState(() => _showHeaderData = value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.text_fields_outlined,
                        label: 'عرض الاسم في رأس الصفحة',
                        value: _showCompanyName,
                        onChanged: (value) => setState(() => _showCompanyName = value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.home_outlined,
                        label: 'عرض العنوان في رأس الصفحة',
                        value: _showCompanyAddress,
                        onChanged: (value) => setState(() => _showCompanyAddress = value),
                      ),
                      _buildSwitchTile(
                        icon: Icons.phone_outlined,
                        label: 'عرض الهاتف في رأس الصفحة',
                        value: _showCompanyPhone,
                        onChanged: (value) => setState(() => _showCompanyPhone = value),
                      ),
                    ],
                  ),
                ),

                // Save Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: () {
        // Could show dropdown dialog here
      },
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        value ? 'مفعل' : 'غير مفعل',
        style: TextStyle(
          fontSize: 12,
          color: value ? Colors.green : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
