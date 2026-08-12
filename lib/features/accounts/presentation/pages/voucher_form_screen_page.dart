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
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/section_header.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/theme/app_text_style.dart';


part 'voucher_form_screen_models.dart';
part 'voucher_form_screen_widgets.dart';

// ==================== FILE 11: screens/voucher_form_screen.dart ====================

class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({Key? key}) : super(key: key);

  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  VoucherType _voucherType = VoucherType.payment;
  VoucherPaymentMethod _paymentMethod = VoucherPaymentMethod.cash;

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
                            maxWidth: 600,
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
        return HasibButton(
          label: _isSaving ? 'جاري الحفظ...' : 'حفظ',
          onPressed: _isSaving ? null : () => _handleSave(context),
          loading: _isSaving,
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
    return CustomCardContainer(
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
    return CustomCardContainer(
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
          CustomDropdownField<AccountEntity>(
            
            isRequired: true,
            value: _selectedAccount,
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
    return CustomCardContainer(
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
       borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gray300,
            width: 2,
            style: BorderStyle.solid,
          ),
           borderRadius: BorderRadius.circular(AppRadius.lg),
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
        const SectionHeader(title: 'طرق الدفع', showChevron: true),
        CustomCardContainer(
          backgroundColor: AppColors.blue50,
          borderColor: AppColors.blue200,
          child: Row(
            children: [
              CustomRadioButton<VoucherPaymentMethod>(
                value: VoucherPaymentMethod.cash,
                groupValue: _paymentMethod,
                label: 'نقداً',
                onChanged: (value) => setState(() => _paymentMethod = value),
              ),
              CustomRadioButton<VoucherPaymentMethod>(
                value: VoucherPaymentMethod.bankTransfer,
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
          title: _paymentMethod == VoucherPaymentMethod.cash
              ? 'تفاصيل الدفع النقدي'
              : 'تفاصيل التحويل البنكي',
          showChevron: true,
        ),
            _paymentMethod == VoucherPaymentMethod.cash
            ? _buildCashPaymentSection()
            : _buildBankTransferSection(),
      ],
    );
  }

  Widget _buildCashPaymentSection() {
    return CustomCardContainer(
      child: Column(
        children: [
          _buildAmountField(),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          CustomDropdownField<AccountEntity>(
            hint: 'الصندوق',
            value: _selectedBoxBank,
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
          CustomDropdownField<CurrencyEntity>(
            hint: 'العملة',
            
            value: _selectedCurrency,
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
    return CustomCardContainer(
      child: Column(
        children: [
          _buildAmountField(),
          const SizedBox(height: 16),
          CustomDropdownField<CurrencyEntity>(
            hint: 'العملة',
            isRequired: true,
            value: _selectedCurrency,
            items: _currencies
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value),
          ),
          const SizedBox(height: 16),
          CustomDropdownField<AccountEntity>(
            
            isRequired: true,
            value: _selectedBoxBank,
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.attach_money,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomDropdownField<CurrencyEntity>(
            
            hint: 'عملة عمولة الحوالة',
            value: _selectedCurrency,
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
