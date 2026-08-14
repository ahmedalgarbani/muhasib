import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/section_header.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/vouchers_cubit.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

part 'voucher_form_screen_models.dart';
part 'voucher_form_screen_widgets.dart';

class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({super.key});

  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  VoucherType _voucherType = VoucherType.payment;
  VoucherPaymentMethod _paymentMethod = VoucherPaymentMethod.cash;

  List<AccountEntity> _accounts = [];
  List<CurrencyEntity> _currencies = [];

  AccountEntity? _selectedAccount;
  CurrencyEntity? _selectedCurrency;
  AccountEntity? _selectedBoxBank;

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
    context.read<VouchersCubit>().refreshNumber(_voucherType);
  }

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
            AppToast.showSuccess(context, state.message);
            Navigator.pop(context);
          } else if (state is VouchersFailure) {
            setState(() => _isSaving = false);
            AppToast.showError(context, state.message);
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
                                VoucherFormHeaderWidget(
                                  onBack: () => Navigator.pop(context),
                                ),
                                const SizedBox(height: 24),
                                VoucherTypeSectionWidget(
                                  voucherType: _voucherType,
                                  onChanged: (value) {
                                    setState(() => _voucherType = value);
                                    context.read<VouchersCubit>().refreshNumber(value);
                                  },
                                ),
                                VoucherBasicInformationSectionWidget(
                                  numberController: _numberController,
                                  dateController: _dateController,
                                  selectedAccount: _selectedAccount,
                                  accounts: _accounts,
                                  onAccountChanged: (val) =>
                                      setState(() => _selectedAccount = val),
                                ),
                                VoucherNotesAndImageSectionWidget(
                                  notesController: _notesController,
                                ),
                                VoucherPaymentMethodSectionWidget(
                                  paymentMethod: _paymentMethod,
                                  onChanged: (val) =>
                                      setState(() => _paymentMethod = val),
                                ),
                                VoucherPaymentDetailsSectionWidget(
                                  paymentMethod: _paymentMethod,
                                  amountController: _amountController,
                                  accounts: _accounts,
                                  currencies: _currencies,
                                  selectedBoxBank: _selectedBoxBank,
                                  selectedCurrency: _selectedCurrency,
                                  accountNumberController: _accountNumberController,
                                  senderNameController: _senderNameController,
                                  recipientNameController: _recipientNameController,
                                  commissionAmountController:
                                      _commissionAmountController,
                                  onBoxBankChanged: (val) =>
                                      setState(() => _selectedBoxBank = val),
                                  onCurrencyChanged: (val) =>
                                      setState(() => _selectedCurrency = val),
                                ),
                                const SizedBox(height: 8),
                                VoucherScreenSaveButtonWidget(
                                  isSaving: _isSaving,
                                  onSave: (ctx) => _handleSave(ctx),
                                ),
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

  void _handleSave(BuildContext context) {
    if (_numberController.text.isEmpty || _dateController.text.isEmpty) {
      AppToast.showError(context, 'يرجى ملء الحقول المطلوبة');
      return;
    }

    if (_selectedAccount == null) {
      AppToast.showError(context, 'يرجى اختيار الحساب');
      return;
    }

    if (_selectedBoxBank == null) {
      AppToast.showError(context, 'يرجى اختيار الصندوق أو البنك');
      return;
    }

    if (_amountController.text.isEmpty) {
      AppToast.showError(context, 'يرجى إدخال المبلغ');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (_voucherType == VoucherType.payment &&
        SettingsCache.checkFundAndBankBalanceInVoucher &&
        amount > _selectedBoxBank!.balance) {
      AppToast.showError(
        context,
        'المبلغ أكبر من الرصيد المتاح للصندوق أو البنك (الرصيد الحالي: ${NumberFormatter.formatNumber(_selectedBoxBank!.balance)})',
      );
      return;
    }

    final voucher = VoucherEntity(
      number: int.tryParse(_numberController.text) ?? 0,
      date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
      statement: _notesController.text.isEmpty
          ? 'سند ${_voucherType.label}'
          : _notesController.text,
      amount: amount,
      accountId: _selectedBoxBank!.id!,
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

class VoucherFormHeaderWidget extends StatelessWidget {
  final VoidCallback onBack;

  const VoucherFormHeaderWidget({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('إضافة سند', style: AppTextStyles.heading1),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.blue600),
          onPressed: onBack,
        ),
      ],
    );
  }
}

class VoucherTypeSectionWidget extends StatelessWidget {
  final VoucherType voucherType;
  final ValueChanged<VoucherType> onChanged;

  const VoucherTypeSectionWidget({
    super.key,
    required this.voucherType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      child: Row(
        children: [
          CustomRadioButton<VoucherType>(
            value: VoucherType.payment,
            groupValue: voucherType,
            label: 'سند صرف',
            onChanged: onChanged,
          ),
          CustomRadioButton<VoucherType>(
            value: VoucherType.receipt,
            groupValue: voucherType,
            label: 'سند قبض',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class VoucherBasicInformationSectionWidget extends StatelessWidget {
  final TextEditingController numberController;
  final TextEditingController dateController;
  final AccountEntity? selectedAccount;
  final List<AccountEntity> accounts;
  final ValueChanged<AccountEntity?> onAccountChanged;

  const VoucherBasicInformationSectionWidget({
    super.key,
    required this.numberController,
    required this.dateController,
    required this.selectedAccount,
    required this.accounts,
    required this.onAccountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  hint: 'الرقم',
                  isRequired: true,
                  textEditingController: numberController,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextInputField(
                  hint: 'تاريخ السند',
                  isRequired: true,
                  textEditingController: dateController,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomDropdownField<AccountEntity>(
            isRequired: true,
            value: selectedAccount,
            items: accounts
                .where((a) => !a.isMaster)
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text('${e.code} - ${e.name}'),
                  ),
                )
                .toList(),
            onChanged: onAccountChanged,
            hint: 'اختر الحساب (الطرف الثاني)',
          ),
        ],
      ),
    );
  }
}

class VoucherNotesAndImageSectionWidget extends StatelessWidget {
  final TextEditingController notesController;

  const VoucherNotesAndImageSectionWidget({
    super.key,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      child: Column(
        children: [
          TextInputField(
            hint: 'أضف ملاحظة...',
            textEditingController: notesController,
            maxLines: 3,
            maxLength: 1000,
            showCharacterCount: true,
          ),
          const SizedBox(height: 16),
          const VoucherImageUploadButtonWidget(),
        ],
      ),
    );
  }
}

class VoucherImageUploadButtonWidget extends StatelessWidget {
  const VoucherImageUploadButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: AppConstant.defaultPadding,
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
}

class VoucherPaymentMethodSectionWidget extends StatelessWidget {
  final VoucherPaymentMethod paymentMethod;
  final ValueChanged<VoucherPaymentMethod> onChanged;

  const VoucherPaymentMethodSectionWidget({
    super.key,
    required this.paymentMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                groupValue: paymentMethod,
                label: 'نقداً',
                onChanged: onChanged,
              ),
              CustomRadioButton<VoucherPaymentMethod>(
                value: VoucherPaymentMethod.bankTransfer,
                groupValue: paymentMethod,
                label: 'حواله بنكية',
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VoucherPaymentDetailsSectionWidget extends StatelessWidget {
  final VoucherPaymentMethod paymentMethod;
  final TextEditingController amountController;
  final List<AccountEntity> accounts;
  final List<CurrencyEntity> currencies;
  final AccountEntity? selectedBoxBank;
  final CurrencyEntity? selectedCurrency;
  final TextEditingController accountNumberController;
  final TextEditingController senderNameController;
  final TextEditingController recipientNameController;
  final TextEditingController commissionAmountController;
  final ValueChanged<AccountEntity?> onBoxBankChanged;
  final ValueChanged<CurrencyEntity?> onCurrencyChanged;

  const VoucherPaymentDetailsSectionWidget({
    super.key,
    required this.paymentMethod,
    required this.amountController,
    required this.accounts,
    required this.currencies,
    required this.selectedBoxBank,
    required this.selectedCurrency,
    required this.accountNumberController,
    required this.senderNameController,
    required this.recipientNameController,
    required this.commissionAmountController,
    required this.onBoxBankChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: paymentMethod == VoucherPaymentMethod.cash
              ? 'تفاصيل الدفع النقدي'
              : 'تفاصيل التحويل البنكي',
          showChevron: true,
        ),
        paymentMethod == VoucherPaymentMethod.cash
            ? VoucherCashPaymentSectionWidget(
                amountController: amountController,
                accounts: accounts,
                currencies: currencies,
                selectedBoxBank: selectedBoxBank,
                selectedCurrency: selectedCurrency,
                onBoxBankChanged: onBoxBankChanged,
                onCurrencyChanged: onCurrencyChanged,
              )
            : VoucherBankTransferSectionWidget(
                amountController: amountController,
                accounts: accounts,
                currencies: currencies,
                selectedBoxBank: selectedBoxBank,
                selectedCurrency: selectedCurrency,
                accountNumberController: accountNumberController,
                senderNameController: senderNameController,
                recipientNameController: recipientNameController,
                commissionAmountController: commissionAmountController,
                onBoxBankChanged: onBoxBankChanged,
                onCurrencyChanged: onCurrencyChanged,
              ),
      ],
    );
  }
}

class VoucherCashPaymentSectionWidget extends StatelessWidget {
  final TextEditingController amountController;
  final List<AccountEntity> accounts;
  final List<CurrencyEntity> currencies;
  final AccountEntity? selectedBoxBank;
  final CurrencyEntity? selectedCurrency;
  final ValueChanged<AccountEntity?> onBoxBankChanged;
  final ValueChanged<CurrencyEntity?> onCurrencyChanged;

  const VoucherCashPaymentSectionWidget({
    super.key,
    required this.amountController,
    required this.accounts,
    required this.currencies,
    required this.selectedBoxBank,
    required this.selectedCurrency,
    required this.onBoxBankChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      child: Column(
        children: [
          VoucherAmountFieldWidget(
            amountController: amountController,
            account: selectedBoxBank,
          ),
          const SizedBox(height: 16),
          CustomDropdownField<AccountEntity>(
            hint: 'الصندوق',
            value: selectedBoxBank,
            items: accounts
                .where(
                  (a) =>
                      !a.isMaster &&
                      (a.name.contains('صندوق') || a.code.startsWith('111')),
                )
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: onBoxBankChanged,
          ),
          if (SettingsCache.allowMultiCurrencyInVoucher) ...[
            const SizedBox(height: 16),
            CustomDropdownField<CurrencyEntity>(
              hint: 'العملة',
              value: selectedCurrency,
              items: currencies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: onCurrencyChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class VoucherBankTransferSectionWidget extends StatelessWidget {
  final TextEditingController amountController;
  final List<AccountEntity> accounts;
  final List<CurrencyEntity> currencies;
  final AccountEntity? selectedBoxBank;
  final CurrencyEntity? selectedCurrency;
  final TextEditingController accountNumberController;
  final TextEditingController senderNameController;
  final TextEditingController recipientNameController;
  final TextEditingController commissionAmountController;
  final ValueChanged<AccountEntity?> onBoxBankChanged;
  final ValueChanged<CurrencyEntity?> onCurrencyChanged;

  const VoucherBankTransferSectionWidget({
    super.key,
    required this.amountController,
    required this.accounts,
    required this.currencies,
    required this.selectedBoxBank,
    required this.selectedCurrency,
    required this.accountNumberController,
    required this.senderNameController,
    required this.recipientNameController,
    required this.commissionAmountController,
    required this.onBoxBankChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      child: Column(
        children: [
          VoucherAmountFieldWidget(
            amountController: amountController,
            account: selectedBoxBank,
          ),
          if (SettingsCache.allowMultiCurrencyInVoucher) ...[
            const SizedBox(height: 16),
            CustomDropdownField<CurrencyEntity>(
              hint: 'العملة',
              isRequired: true,
              value: selectedCurrency,
              items: currencies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: onCurrencyChanged,
            ),
          ],
          const SizedBox(height: 16),
          CustomDropdownField<AccountEntity>(
            isRequired: true,
            value: selectedBoxBank,
            items: accounts
                .where(
                  (a) =>
                      !a.isMaster &&
                      (a.name.contains('بنك') || a.code.startsWith('112')),
                )
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: onBoxBankChanged,
            hint: 'اختر البنك',
          ),
          const SizedBox(height: 16),
          TextInputField(
            label: 'رقم الحساب',
            isRequired: true,
            hint: 'أدخل رقم الحساب',
            textEditingController: accountNumberController,
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
                  textEditingController: senderNameController,
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
                  textEditingController: recipientNameController,
                  maxLength: 50,
                  showCharacterCount: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          VoucherCommissionSectionWidget(
            commissionAmountController: commissionAmountController,
            selectedCurrency: selectedCurrency,
            currencies: currencies,
            onCurrencyChanged: onCurrencyChanged,
          ),
        ],
      ),
    );
  }
}

class VoucherAmountFieldWidget extends StatelessWidget {
  final TextEditingController amountController;
  final AccountEntity? account;

  const VoucherAmountFieldWidget({
    super.key,
    required this.amountController,
    this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInputField(
          label: 'المبلغ',
          isRequired: true,
          hint: '0.00',
          textEditingController: amountController,
          inputType: TextInputType.number,
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
        if (SettingsCache.showAccountBalanceInVoucher && account != null) ...[
          const SizedBox(height: 8),
          Text(
            'الرصيد الحالي: ${NumberFormatter.formatNumber(account!.balance)}',
            style: AppTextStyles.body.copyWith(
              color: account!.balance >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class VoucherCommissionSectionWidget extends StatelessWidget {
  final TextEditingController commissionAmountController;
  final CurrencyEntity? selectedCurrency;
  final List<CurrencyEntity> currencies;
  final ValueChanged<CurrencyEntity?> onCurrencyChanged;

  const VoucherCommissionSectionWidget({
    super.key,
    required this.commissionAmountController,
    required this.selectedCurrency,
    required this.currencies,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
        ),
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
            textEditingController: commissionAmountController,
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
          if (SettingsCache.allowMultiCurrencyInVoucher) ...[
            const SizedBox(height: 16),
            CustomDropdownField<CurrencyEntity>(
              hint: 'عملة عمولة الحوالة',
              value: selectedCurrency,
              items: currencies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: onCurrencyChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class VoucherScreenSaveButtonWidget extends StatelessWidget {
  final bool isSaving;
  final ValueChanged<BuildContext> onSave;

  const VoucherScreenSaveButtonWidget({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return HasibButton(
      label: isSaving ? 'جاري الحفظ...' : 'حفظ',
      onPressed: isSaving ? null : () => onSave(context),
      loading: isSaving,
    );
  }
}
