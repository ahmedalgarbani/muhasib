// ==================== FILE 1: models/voucher_model.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/core/models/test/VoucherFormData.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';
import 'package:muhasib/features/accounts/presentation/pages/currencies_manage_page.dart';
import 'package:hasib_lib/base/entity.dart';
import 'package:hasib_lib/form/form_field.dart';
import 'package:hasib_lib/theme/app_colors.dart';

// ==================== FILE 3: constants/app_text_styles.dart ====================

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gray700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle radioActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.blue600,
  );

  static const TextStyle radioInactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gray700,
  );
}

// ==================== FILE 4: constants/app_dimensions.dart ====================
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  static const double borderWidth = 2.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  static const double radioSize = 24.0;
  static const double radioInnerSize = 12.0;

  static const double inputHeight = 48.0;
  static const double buttonHeight = 56.0;

  static const double maxWidth = 600.0;
}

class CustomRadioButton<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T> onChanged;

  const CustomRadioButton({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Row(
          children: [
            Container(
              width: AppDimensions.radioSize,
              height: AppDimensions.radioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.blue50 : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.blue600 : AppColors.gray300,
                  width: AppDimensions.borderWidth,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: AppDimensions.radioInnerSize,
                        height: AppDimensions.radioInnerSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue600,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.radioActive
                  : AppTextStyles.radioInactive,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FILE 8: widgets/section_header.dart ====================

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showChevron;

  const SectionHeader({Key? key, required this.title, this.showChevron = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.heading2),
          if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: AppColors.blue600,
              size: AppDimensions.iconSizeSmall,
            ),
        ],
      ),
    );
  }
}

// ==================== FILE 9: widgets/card_container.dart ====================

class CardContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const CardContainer({
    Key? key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.gray100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
        border: Border.all(color: borderColor!, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================== FILE 10: widgets/primary_button.dart ====================

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({Key? key, required this.text, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue600, AppColors.blue700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
          child: Center(child: Text(text, style: AppTextStyles.buttonLarge)),
        ),
      ),
    );
  }
}

// ==================== FILE 11: screens/voucher_form_screen.dart ====================

class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({Key? key}) : super(key: key);

  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  VoucherType _voucherType = VoucherType.expense;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  VoucherFormData _formData = VoucherFormData();

  final TextEditingController _numberController = TextEditingController(
    text: '1',
  );
  final TextEditingController _dateController = TextEditingController(
    text: '17-10-2025',
  );
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _commissionAmountController =
      TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    _senderNameController.dispose();
    _recipientNameController.dispose();
    _commissionAmountController.dispose();
    super.dispose();
  }

  void _updateFormData(String field, String value) {
    setState(() {
      switch (field) {
        case 'number':
          _formData = _formData.copyWith(number: value);
          break;
        case 'date':
          _formData = _formData.copyWith(date: value);
          break;
        case 'account':
          _formData = _formData.copyWith(account: value);
          break;
        case 'notes':
          _formData = _formData.copyWith(notes: value);
          break;
        case 'amount':
          _formData = _formData.copyWith(amount: value);
          break;
        case 'currency':
          _formData = _formData.copyWith(currency: value);
          break;
        case 'bank':
          _formData = _formData.copyWith(bank: value);
          break;
        case 'accountNumber':
          _formData = _formData.copyWith(accountNumber: value);
          break;
        case 'senderName':
          _formData = _formData.copyWith(senderName: value);
          break;
        case 'recipientName':
          _formData = _formData.copyWith(recipientName: value);
          break;
        case 'commissionAmount':
          _formData = _formData.copyWith(commissionAmount: value);
          break;
        case 'commissionCurrency':
          _formData = _formData.copyWith(commissionCurrency: value);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildVoucherTypeSection(),
                      _buildBasicInformationSection(),
                      _buildNotesAndImageSection(),
                      _buildPaymentMethodSection(),
                      _buildPaymentDetailsSection(),
                      const SizedBox(height: 8),
                      PrimaryButton(text: 'حفظ', onPressed: _handleSave),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('إضافة سند', style: AppTextStyles.heading1),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.blue600),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildVoucherTypeSection() {
    return CardContainer(
      child: Row(
        children: [
          CustomRadioButton<VoucherType>(
            value: VoucherType.expense,
            groupValue: _voucherType,
            label: 'سند صرف',
            onChanged: (value) => setState(() => _voucherType = value),
          ),
          CustomRadioButton<VoucherType>(
            value: VoucherType.receipt,
            groupValue: _voucherType,
            label: 'سند قبض',
            onChanged: (value) => setState(() => _voucherType = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return CardContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  hint: 'الرقم',
                  isRequired: true,
                  textEditingController: _numberController,
                  onChanged: (value) => _updateFormData('number', value),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextInputField(
                  hint: 'تاريخ السند',
                  isRequired: true,
                  textEditingController: _dateController,
                  onChanged: (value) => _updateFormData('date', value),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldSelect<AccountModel>(
            showHint: true,
            isRequired: true,
            // value: _formData.account,
            items: [],
            onChanged: (value) => _updateFormData('account', ''),
            hint: 'اختر الحساب',
          ),
        ],
      ),
    );
  }

  Widget _buildNotesAndImageSection() {
    return CardContainer(
      child: Column(
        children: [
          TextInputField(
            // label: 'الملاحظة',
            hint: 'أضف ملاحظة...',
            textEditingController: _notesController,
            onChanged: (value) => _updateFormData('notes', value),
            maxLines: 3,
            maxLength: 1000,
            showCharacterCount: true,
          ),
          const SizedBox(height: 16),
          _buildImageUploadButton(),
        ],
      ),
    );
  }

  Widget _buildImageUploadButton() {
    return InkWell(
      onTap: () {
        // Handle image upload
      },
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gray300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.gray600,
            ),
            const SizedBox(width: 8),
            Text(
              'إرفاق صورة',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'طرق الدفع'),
        CardContainer(
          backgroundColor: AppColors.blue50,
          borderColor: AppColors.blue200,
          child: Row(
            children: [
              CustomRadioButton<PaymentMethod>(
                value: PaymentMethod.cash,
                groupValue: _paymentMethod,
                label: 'نقداً',
                onChanged: (value) => setState(() => _paymentMethod = value),
              ),
              CustomRadioButton<PaymentMethod>(
                value: PaymentMethod.bankTransfer,
                groupValue: _paymentMethod,
                label: 'حواله بنكية',
                onChanged: (value) => setState(() => _paymentMethod = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _paymentMethod == PaymentMethod.cash
              ? 'تفاصيل الدفع النقدي'
              : 'تفاصيل التحويل البنكي',
        ),
        _paymentMethod == PaymentMethod.cash
            ? _buildCashPaymentSection()
            : _buildBankTransferSection(),
      ],
    );
  }

  Widget _buildCashPaymentSection() {
    return CardContainer(
      child: Column(
        children: [
          _buildAmountField(),
          const SizedBox(height: 16),
          TextFieldSelect<Boxess>(
            hint: 'الصندوق',
            // value: '',
            items: [Boxess('الصندوق الرئيسي'), Boxess('صندوق فرعي')],
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          TextFieldSelect<Currency>(
            hint: 'العملة',
            showHint: true,
            // selectedValue : _formData.currency,
            items: const [],
            onChanged: (value) => _updateFormData('currency', 'USD'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferSection() {
    return CardContainer(
      child: Column(
        children: [
          _buildAmountField(),
          const SizedBox(height: 16),
          TextFieldSelect<Currency>(
            hint: 'العملة',
            isRequired: true,
            // value: _formData.currency,
            items: const [],
            onChanged: (value) => _updateFormData('currency', 'USD'),
          ),
          const SizedBox(height: 16),
          TextFieldSelect<Boxess>(
            showHint: true,
            isRequired: true,
            // value: _formData.bank,
            items: [
              Boxess('اختر البنك'),
              Boxess('البنك الأهلي'),
              Boxess('البنك الزراعي'),
              Boxess('بنك مصر'),
            ],
            onChanged: (value) => _updateFormData('bank', ''),
            hint: 'اختر البنك',
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'رقم الحساب',
            isRequired: true,
            hint: 'أدخل رقم الحساب',
            // controller: _accountNumberController,
            onChanged: (value) => _updateFormData('accountNumber', value),
            maxLength: 20,
            showCharacterCount: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  label: 'اسم المرسل',
                  isRequired: true,
                  hint: 'الاسم',
                  // controller: _senderNameController,
                  onChanged: (value) => _updateFormData('senderName', value),
                  maxLength: 50,
                  showCharacterCount: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextInputField(
                  label: 'اسم المستقبل',
                  isRequired: true,
                  hint: 'الاسم',
                  // controller: _recipientNameController,
                  onChanged: (value) => _updateFormData('recipientName', value),
                  maxLength: 50,
                  showCharacterCount: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommissionSection(),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextInputField(
      label: 'المبلغ',
      isRequired: true,
      hint: '0.00',
      // controller: _amountController,
      onChanged: (value) => _updateFormData('amount', value),
      inputType: TextInputType.number,
      suffixIcon: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.blue600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.attach_money, color: AppColors.white, size: 20),
      ),
    );
  }

  Widget _buildCommissionSection() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chevron_right,
                color: AppColors.blue600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text('عمولة الحوالة', style: AppTextStyles.heading2),
            ],
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'مبلغ عمولة الحوالة',
            isRequired: true,
            hint: '0.00',
            // controller: _commissionAmountController,
            onChanged: (value) => _updateFormData('commissionAmount', value),
            inputType: TextInputType.number,

            backgroundColor: AppColors.darkSecondary.withOpacity(0.1),
            borderColor: AppColors.darkSecondary,
            focusBorderColor: AppColors.darkSecondary,
            suffixIcon: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.attach_money,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFieldSelect<Currency>(
            showHint: true,
            hint: 'عملة عمولة الحوالة',
            // selectedValue: _formData.commissionCurrency,
            items: [],
            onChanged: (value) => _updateFormData('commissionCurrency', 'USD'),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    // Implement save logic
    print('Form saved with data: $_formData');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ السند بنجاح')));
  }
}

class Boxess extends Entity {
  String? name;
  Boxess(this.name);
  @override
  // TODO: implement route
  String? get route => 'throw UnimplementedError()';

  @override
  // TODO: implement toJson
  Map get toJson => throw UnimplementedError();
}
