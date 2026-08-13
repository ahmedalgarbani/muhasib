import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_state.dart';

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
      text: personalInfo['AddressFrn'] ?? 'Sana\'a',
    );
    _phoneController = TextEditingController(
      text: personalInfo['phone'] ?? '967782767927',
    );
    _emailController = TextEditingController(text: personalInfo['email'] ?? '');
    _taxNumberController = TextEditingController(
      text: personalInfo['taxNo'] ?? '',
    );
    _commercialRegisterController = TextEditingController(
      text: personalInfo['commercialRegister'] ?? '',
    );
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

  Future<void> _saveSettings() async {
    final cubit = context.read<SettingsCubit>();
    final personalInfo = {
      'name': _nameArController.text,
      'nameFrn': _nameEnController.text,
      'address': _addressArController.text,
      'AddressFrn': _addressEnController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'taxNo': _taxNumberController.text,
      'commercialRegister': _commercialRegisterController.text,
      'logoPath': null,
      'signature': null,
      'sealingPath': null,
    };

    await cubit.updateSetting('personal_info', personalInfo);

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
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                  _buildCard([
                    _buildTextField(
                      controller: _nameArController,
                      label: 'الاسم باللغة المحلية',
                      hint: 'حسيب',
                      icon: Icons.person_outline,
                    ),
                    const Divider(),
                    _buildTextField(
                      controller: _nameEnController,
                      label: 'الاسم باللغة الاجنبية',
                      hint: 'Hasib',
                      icon: Icons.person_outline,
                    ),
                    const Divider(),
                    _buildTextField(
                      controller: _addressArController,
                      label: 'العنوان باللغة المحلية',
                      hint: 'صنعاء',
                      icon: Icons.home_outlined,
                    ),
                    const Divider(),
                    _buildTextField(
                      controller: _addressEnController,
                      label: 'العنوان باللغة الاجنبية',
                      hint: 'Sana\'a',
                      icon: Icons.home_work_outlined,
                    ),
                  ]),
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
                  _buildCard([
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الموبايل',
                      hint: '967782767927',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(),
                    _buildTextField(
                      controller: _commercialRegisterController,
                      label: 'السجل التجاري',
                      hint: '',
                      icon: Icons.badge_outlined,
                    ),
                  ]),
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
                  _buildCard([
                    _buildTextField(
                      controller: _taxNumberController,
                      label: 'الرقم الضريبي',
                      hint: '',
                      icon: Icons.tag,
                    ),
                  ]),
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
                  _buildCard([
                    _buildImagePicker(
                      label: 'الشعار',
                      icon: Icons.image_outlined,
                      onTap: () {
                        // TODO: Implement image picker for logo
                      },
                    ),
                    const Divider(),
                    _buildImagePicker(
                      label: 'الختم',
                      icon: Icons.verified_user_outlined,
                      onTap: () {
                        // TODO: Implement image picker for seal
                      },
                    ),
                    const Divider(),
                    _buildImagePicker(
                      label: 'التوقيع',
                      icon: Icons.draw_outlined,
                      onTap: () {
                        // TODO: Implement image picker for signature
                      },
                    ),
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
          }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: TextInputField(
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
    );
  }
}
