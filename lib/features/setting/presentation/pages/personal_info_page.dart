import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/media_storage_service.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _addressArController;
  late TextEditingController _addressEnController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _taxNumberController;
  late TextEditingController _commercialRegisterController;
  String? _logoPath;
  String? _sealPath;
  String? _signaturePath;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    final personalInfo = cubit.getPersonalInfo();

    _nameArController = TextEditingController(
      text: personalInfo['name'] ?? 'محاسب',
    );
    _nameEnController = TextEditingController(
      text: personalInfo['nameFrn'] ?? 'Hasib',
    );
    _addressArController = TextEditingController(
      text: personalInfo['address'] ?? 'صنعاء',
    );
    _addressEnController = TextEditingController(
      text: personalInfo['AddressFrn'] ?? 'Sana\'a',
    );
    _phoneController = TextEditingController(
      text: personalInfo['phone'] ?? '967782767927',
    );
    _emailController = TextEditingController(
      text: personalInfo['company_email'] ?? '',
    );
    _taxNumberController = TextEditingController(
      text: personalInfo['taxNo'] ?? '',
    );
    _commercialRegisterController = TextEditingController(
      text: personalInfo['company_commercial_register'] ?? '',
    );
    _logoPath = personalInfo['logoPath']?.toString();
    _sealPath = personalInfo['sealingPath']?.toString();
    _signaturePath = personalInfo['signature']?.toString();
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _commercialRegisterController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String field) async {
    final path = await getIt<MediaStorageService>().pickAndStoreImage(
      fileName: field,
    );
    if (path == null || !mounted) return;
    setState(() {
      switch (field) {
        case 'logo':
          _logoPath = path;
          break;
        case 'seal':
          _sealPath = path;
          break;
        case 'signature':
          _signaturePath = path;
          break;
      }
    });
    AppToast.showSuccess(context, 'تم اختيار الصورة، لا تنسَ حفظ التغييرات');
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final personalInfo = {
      'name': _nameArController.text,
      'nameFrn': _nameEnController.text,
      'address': _addressArController.text,
      'AddressFrn': _addressEnController.text,
      'phone': _phoneController.text,
      'company_email': _emailController.text,
      'taxNo': _taxNumberController.text,
      'company_commercial_register': _commercialRegisterController.text,
      'logoPath': _logoPath,
      'sealingPath': _sealPath,
      'signature': _signaturePath,
    };

    await cubit.updateSetting('personal_info', personalInfo);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ البيانات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'البيانات الشخصية'),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return SingleChildScrollView(
              padding: AppConstant.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'الاسم - العنوان',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SettingsCard(
                    children: [
                      SettingsTextFieldTile(
                        controller: _nameArController,
                        title: 'الاسم باللغة المحلية',
                        hintText: 'محاسب',
                        icon: Icons.person_outline,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        controller: _nameEnController,
                        title: 'الاسم باللغة الاجنبية',
                        hintText: 'Hasib',
                        icon: Icons.person_outline,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        controller: _addressArController,
                        title: 'العنوان باللغة المحلية',
                        hintText: 'صنعاء',
                        icon: Icons.home_outlined,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        controller: _addressEnController,
                        title: 'العنوان باللغة الاجنبية',
                        hintText: 'Sana\'a',
                        icon: Icons.home_work_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'بيانات التواصل',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SettingsCard(
                    children: [
                      SettingsTextFieldTile(
                        controller: _phoneController,
                        title: 'رقم الموبايل',
                        hintText: '967782767927',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const Divider(),
                      SettingsTextFieldTile(
                        controller: _commercialRegisterController,
                        title: 'السجل التجاري',
                        hintText: '',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'بيانات الضرائب',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SettingsCard(
                    children: [
                      SettingsTextFieldTile(
                        controller: _taxNumberController,
                        title: 'الرقم الضريبي',
                        hintText: '',
                        icon: Icons.tag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'بيانات اخرى',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SettingsCard(
                    children: [
                      _ImageFieldTile(
                        label: 'الشعار',
                        icon: Icons.image_outlined,
                        path: _logoPath,
                        onPick: () => _pickImage('logo'),
                        onClear: () => setState(() => _logoPath = null),
                      ),
                      const Divider(),
                      _ImageFieldTile(
                        label: 'الختم',
                        icon: Icons.verified_user_outlined,
                        path: _sealPath,
                        onPick: () => _pickImage('seal'),
                        onClear: () => setState(() => _sealPath = null),
                      ),
                      const Divider(),
                      _ImageFieldTile(
                        label: 'التوقيع',
                        icon: Icons.draw_outlined,
                        path: _signaturePath,
                        onPick: () => _pickImage('signature'),
                        onClear: () => setState(() => _signaturePath = null),
                      ),
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
          }
        },
      ),
    );
  }
}

class _ImageFieldTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImageFieldTile({
    required this.label,
    required this.icon,
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  bool get _hasImage {
    final value = path;
    if (value == null || value.isEmpty) return false;
    try {
      return File(value).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          : Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        _hasImage ? 'تم الرفع' : 'لم يتم الرفع',
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasImage)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'إزالة',
              onPressed: onClear,
            ),
          TextButton(
            onPressed: onPick,
            child: Text(_hasImage ? 'تغيير' : 'اختيار'),
          ),
        ],
      ),
    );
  }
}
