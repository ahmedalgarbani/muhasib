import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/core/widgets/settings_card.dart';
import 'package:muhasib/core/widgets/settings_text_field_tile.dart';
import 'package:muhasib/core/widgets/settings_image_picker_tile.dart';
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
  late TextEditingController _phoneFrnController;
  late TextEditingController _taxNumberController;
  late TextEditingController _commercialRegisterController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    final personalInfo = cubit.getPersonalInfo();

    _nameArController = TextEditingController(
      text: personalInfo['name'] ?? 'حسيب',
    );
    _nameEnController = TextEditingController(
      text: personalInfo['nameFrn'] ?? 'Hasib',
    );
    _addressArController = TextEditingController(
      text: personalInfo['address'] ?? 'صنعاء',
    );
    _addressEnController = TextEditingController(
      text: personalInfo['AddressFrn'] ?? "Sana'a",
    );
    _phoneController = TextEditingController(
      text: personalInfo['phone'] ?? '967782767927',
    );
    _phoneFrnController = TextEditingController(
      text: personalInfo['phoneFrn'] ?? '967782767927',
    );
    _taxNumberController = TextEditingController(
      text: personalInfo['taxNo'] ?? '',
    );
    _commercialRegisterController = TextEditingController(
      text: personalInfo['company_commercial_register'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _phoneController.dispose();
    _phoneFrnController.dispose();
    _taxNumberController.dispose();
    _commercialRegisterController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final personalInfo = cubit.getPersonalInfo();
    final updatedInfo = {
      ...personalInfo,
      'name': _nameArController.text,
      'nameFrn': _nameEnController.text,
      'address': _addressArController.text,
      'AddressFrn': _addressEnController.text,
      'phone': _phoneController.text,
      'phoneFrn': _phoneFrnController.text,
      'taxNo': _taxNumberController.text,
      'company_commercial_register': _commercialRegisterController.text,
    };

    await cubit.updateSetting('personal_info', updatedInfo);

    if (mounted) {
      AppToast.showSuccess(context, 'تم حفظ البيانات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: CustomAppBar(title: 'البيانات الشخصية'),
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
                // Section: الاسم - العنوان
                const Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 16,
                    end: 16,
                    top: 8,
                    bottom: 4,
                  ),
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
                      icon: Icons.person_outline,
                      title: 'الاسم باللغة المحلية',
                      controller: _nameArController,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      icon: Icons.person_outline,
                      title: 'الاسم باللغة الأجنبية',
                      controller: _nameEnController,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      icon: Icons.home_outlined,
                      title: 'العنوان باللغة المحلية',
                      controller: _addressArController,
                    ),
                    const Divider(),
                    SettingsTextFieldTile(
                      icon: Icons.home_outlined,
                      title: 'العنوان باللغة الأجنبية',
                      controller: _addressEnController,
                    ),
                  ],
                ),

                // Section: بيانات التواصل
                const Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 4,
                  ),
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
                      icon: Icons.phone_outlined,
                      title: 'رقم الموبايل',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                // Section: الهوية التعريفية
                const Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 4,
                  ),
                  child: Text(
                    'الهوية التعريفية',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SettingsCard(
                  children: [
                    SettingsImagePickerTile(
                      icon: Icons.image_outlined,
                      label: 'الشعار',
                      onTap: () {
                        // TODO: Implement image picker
                      },
                    ),
                    const Divider(),
                    SettingsImagePickerTile(
                      icon: Icons.verified_user_outlined,
                      label: 'الختم',
                      onTap: () {
                        // TODO: Implement image picker
                      },
                    ),
                    const Divider(),
                    SettingsImagePickerTile(
                      icon: Icons.draw_outlined,
                      label: 'التوقيع',
                      onTap: () {
                        // TODO: Implement image picker
                      },
                    ),
                  ],
                ),

                // Section: بيانات الضرائب
                const Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 4,
                  ),
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
                      icon: Icons.tag,
                      title: 'الرقم الضريبي',
                      controller: _taxNumberController,
                    ),
                  ],
                ),

                Padding(
                  padding: AppConstant.defaultPadding,
                  child: HasibButton(
                    label: 'حفظ',
                    onPressed: _saveSettings,
                    variant: HasibButtonVariant.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}