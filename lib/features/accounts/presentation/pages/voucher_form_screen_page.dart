// ==================== FILE 1: models/voucher_model.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/vouchers_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:intl/intl.dart';
import 'package:hasib_lib/base/entity.dart';
import 'package:hasib_lib/form/form_field.dart';
import 'package:hasib_lib/theme/app_colors.dart';

// ==================== PaymentMethod Enum ====================
enum PaymentMethod { cash, bankTransfer }

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

// ==================== TextFieldSelect Widget ====================

class TextFieldSelect<T> extends StatelessWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final bool showHint;
  final bool isRequired;
  final String? errorText;

  const TextFieldSelect({
    Key? key,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.showHint = false,
    this.isRequired = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: hint,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: isRequired ? (value) => value == null ? 'مطلوب' : null : null,
      items: items,
      onChanged: onChanged,
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
  VoucherType _voucherType = VoucherType.payment;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  // Data lists
  List<AccountEntity> _accounts = [];
  List<CurrencyEntity> _currencies = [];

  // Selected values
  AccountEntity? _selectedAccount;
  CurrencyEntity? _selectedCurrency;
  AccountEntity? _selectedBoxBank; // Cash box or Bank account

  bool _isSaving = false;

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
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

  @override
  void initState() {
    super.initState();
    // Generate initial number
    context.read<VouchersCubit>().refreshNumber(_voucherType);
  }

  // Form data is managed via controllers and selected values directly

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<VouchersCubit>()),
        BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAllAccounts()),
        BlocProvider(
          create: (_) => getIt<CurrenciesCubit>()..loadAllCurrencies(),
        ),
      ],
      child: BlocListener<VouchersCubit, VouchersState>(
        listener: (context, state) {
          if (state is VoucherActionInProgress) {
            setState(() => _isSaving = true);
          } else if (state is VoucherActionSuccess) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is VouchersFailure) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is VoucherNumberGenerated) {
            _numberController.text = state.number.toString();
          }
        },
        child: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accountsState) {
            if (accountsState is AccountsLoaded) {
              _accounts = accountsState.accounts;
            }

            return BlocBuilder<CurrenciesCubit, CurrenciesState>(
              builder: (context, currenciesState) {
                if (currenciesState is CurrenciesLoaded) {
                  _currencies = currenciesState.currencies;
                  if (_selectedCurrency == null && _currencies.isNotEmpty) {
                    _selectedCurrency = _currencies.firstWhere(
                      (c) => c.isLocalCurrency,
                      orElse: () => _currencies.first,
                    );
                  }
                }

                return Scaffold(
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
                                _buildSaveButton(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Builder(
      builder: (context) {
        return PrimaryButton(
          text: _isSaving ? 'جاري الحفظ...' : 'حفظ',
          onPressed: _isSaving ? () {} : () => _handleSave(context),
        );
      },
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
            value: VoucherType.payment,
            groupValue: _voucherType,
            label: 'سند صرف',
            onChanged: (value) {
              setState(() => _voucherType = value);
              context.read<VouchersCubit>().refreshNumber(value);
            },
          ),
          CustomRadioButton<VoucherType>(
            value: VoucherType.receipt,
            groupValue: _voucherType,
            label: 'سند قبض',
            onChanged: (value) {
              setState(() => _voucherType = value);
              context.read<VouchersCubit>().refreshNumber(value);
            },
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
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextInputField(
                  hint: 'تاريخ السند',
                  isRequired: true,
                  textEditingController: _dateController,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          TextFieldSelect<AccountEntity>(
            showHint: true,
            isRequired: true,
            selectedValue: _selectedAccount,
            items: _accounts
                .where((a) => !a.isMaster)
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text('${e.code} - ${e.name}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedAccount = value),
            hint: 'اختر الحساب (الطرف الثاني)',
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
          const SizedBox(height: 16),
          TextFieldSelect<AccountEntity>(
            hint: 'الصندوق',
            selectedValue: _selectedBoxBank,
            items: _accounts
                .where(
                  (a) =>
                      !a.isMaster &&
                      (a.name.contains('صندوق') || a.code.startsWith('111')),
                )
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedBoxBank = value),
          ),
          const SizedBox(height: 16),
          TextFieldSelect<CurrencyEntity>(
            hint: 'العملة',
            showHint: true,
            selectedValue: _selectedCurrency,
            items: _currencies
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value),
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
          TextFieldSelect<CurrencyEntity>(
            hint: 'العملة',
            isRequired: true,
            selectedValue: _selectedCurrency,
            items: _currencies
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value),
          ),
          const SizedBox(height: 16),
          TextFieldSelect<AccountEntity>(
            showHint: true,
            isRequired: true,
            selectedValue: _selectedBoxBank,
            items: _accounts
                .where(
                  (a) =>
                      !a.isMaster &&
                      (a.name.contains('بنك') || a.code.startsWith('112')),
                )
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedBoxBank = value),
            hint: 'اختر البنك',
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'رقم الحساب',
            isRequired: true,
            hint: 'أدخل رقم الحساب',
            textEditingController: _accountNumberController,
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
                  textEditingController: _senderNameController,
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
                  textEditingController: _recipientNameController,
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
      textEditingController: _amountController,
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
            textEditingController: _commissionAmountController,
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
          TextFieldSelect<CurrencyEntity>(
            showHint: true,
            hint: 'عملة عمولة الحوالة',
            selectedValue: _selectedCurrency,
            items: _currencies
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value),
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context) {
    if (_numberController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء الحقول المطلوبة')));
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار الحساب')));
      return;
    }

    if (_selectedBoxBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الصندوق أو البنك')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال المبلغ')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Create Voucher Entity
    final voucher = VoucherEntity(
      number: int.tryParse(_numberController.text) ?? 0,
      date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
      statement: _notesController.text.isEmpty
          ? 'سند ${_voucherType.label}'
          : _notesController.text,
      amount: amount,
      accountId: _selectedBoxBank!.id!, // Main account (Cash/Bank)
      accountName: _selectedBoxBank!.name,
      type: _voucherType,
      currencyId: _selectedCurrency?.id,
      currencyCode: _selectedCurrency?.code,
      lines: [
        VoucherLineEntity(
          accountId: _selectedAccount!.id,
          accountName: _selectedAccount!.name,
          amount: amount,
          statement: _notesController.text,
        ),
      ],
    );

    context.read<VouchersCubit>().saveVoucher(voucher);
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
