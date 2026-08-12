import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import '../cubit/vouchers_cubit.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';

part 'voucher_form_widgets.dart';

class VoucherFormPage extends StatefulWidget {
  final VoucherEntity? voucher;
  final VoucherType defaultType;

  const VoucherFormPage({super.key, this.voucher, required this.defaultType});

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = intl.DateFormat('yyyy/MM/dd');

  late VoucherType _type;
  late DateTime _date;
  late TextEditingController _numberController;
  late TextEditingController _statementController;
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  int? _accountId;
  String? _accountName;
  final List<_VoucherLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    final voucher = widget.voucher;
    _type = voucher?.type ?? widget.defaultType;
    _date = voucher?.date ?? DateTime.now();
    _numberController = TextEditingController(
      text: voucher?.number.toString() ?? '',
    );
    _statementController = TextEditingController(
      text: voucher?.statement ?? '',
    );
    _amountController = TextEditingController(
      text: voucher != null ? voucher.amount.toStringAsFixed(2) : '',
    );
    _referenceController = TextEditingController(
      text: voucher?.referenceNumber ?? '',
    );
    _accountId = voucher?.accountId;
    _accountName = voucher?.accountName;

    if (voucher != null && voucher.lines.isNotEmpty) {
      for (final line in voucher.lines) {
        _lines.add(
          _VoucherLineInput(
            accountId: line.accountId,
            accountName: line.accountName,
            amount: line.amount,
            statement: line.statement,
          ),
        );
      }
    }

    if (voucher == null) {
      context.read<VouchersCubit>().refreshNumber(_type);
    }

    final accountsCubit = context.read<AccountsCubit>();
    if (accountsCubit.allAccounts == null) {
      accountsCubit.loadAllAccounts();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _statementController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocListener<VouchersCubit, VouchersState>(
        listener: (context, state) {
          if (state is VoucherActionSuccess) {
            AppToast.showSuccess(context, state.message);
            Navigator.of(context).pop(true);
          } else if (state is VouchersFailure) {
            AppToast.showError(context, state.message);
          } else if (state is VoucherNumberGenerated &&
              widget.voucher == null &&
              state.type == _type) {
            _numberController.text = state.number.toString();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: widget.voucher == null
                ? 'إضافة ${_type.label}'
                : 'تعديل ${_type.label}',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSection(),
                  const SizedBox(height: 20),
                  _buildAccountAndAmount(),
                  const SizedBox(height: 20),
                  _buildStatementField(),
                  const SizedBox(height: 24),
                  _buildLinesSection(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextInputField(
                      label: 'رقم السند',
                      textEditingController: _numberController,
                      inputType: TextInputType.number,
                      validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تاريخ السند',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateFormat.format(_date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTypeToggle(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadius.sm14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              VoucherType.receipt,
              'سند قبض',
              Icons.call_received,
            ),
          ),
          Expanded(
            child: _toggleButton(
              VoucherType.payment,
              'سند صرف',
              Icons.call_made,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(VoucherType type, String label, IconData icon) {
    final isSelected = _type == type;
    final color = type == VoucherType.receipt ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () {
        setState(() => _type = type);
        if (widget.voucher == null) {
          context.read<VouchersCubit>().refreshNumber(_type);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountAndAmount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الحساب الرئيسي (أمين الصندوق/الحساب)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _AccountPickerField(
            selectedAccountName: _accountName,
            onTap: () => _pickAccount(isLine: false),
          ),
          const SizedBox(height: 16),
          const Text(
            'المبلغ الإجمالي',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          TextInputField(
            textEditingController: _amountController,
            inputType: TextInputType.number,
            prefixIcon: const Icon(
              Icons.payments_outlined,
              color: AppColors.primary,
            ),
            hint: '0.00',
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل مبلغ صحيح' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatementField() {
    return TextInputField(
      label: 'البيان العام لسند ${_type.label}',
      textEditingController: _statementController,
      maxLines: 2,
      prefixIcon: const Icon(Icons.description_outlined),
      validator: (value) => (value?.isEmpty ?? true) ? 'البيان مطلوب' : null,
    );
  }

  Widget _buildLinesSection() {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تفاصيل السطور (اختياري)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_VoucherLineInput())),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة سطر'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_lines.isEmpty)
          const Text(
            'في حال عدم إضافة سطور، سيتم توجيه المبلغ بالكامل للحساب الرئيسي المختار أعلاه.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ..._lines.asMap().entries.map(
          (entry) => _buildLineCard(entry.key, entry.value, accounts),
        ),
      ],
    );
  }

  Widget _buildLineCard(
    int index,
    _VoucherLineInput line,
    List<AccountEntity> accounts,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _AccountPickerField(
            selectedAccountName: line.accountName,
            onTap: () => _pickAccount(isLine: true, lineIndex: index),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextInputField(
                  label: 'المبلغ',
                  textEditingController: line.amountController,
                  inputType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: TextInputField(
                  label: 'بيان السطر',
                  textEditingController: line.statementController,
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _lines.removeAt(index).dispose()),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<VouchersCubit, VouchersState>(
      builder: (context, state) {
        final saving = state is VoucherActionInProgress;
        return HasibButton(
          label: 'حفظ السند الآن',
          loading: saving,
          onPressed: saving ? null : _onSave,
          variant: HasibButtonVariant.primary,
        );
      },
    );
  }

  void _pickAccount({required bool isLine, int? lineIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _AccountSelectorSheet(
        onSelected: (account) {
          setState(() {
            if (isLine) {
              _lines[lineIndex!].accountId = account.id;
              _lines[lineIndex].accountName = account.name;
            } else {
              _accountId = account.id;
              _accountName = account.name;
            }
          });
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      AppToast.showError(context, 'يجب اختيار الحساب الرئيسي');
      return;
    }

    final headerAmount = double.tryParse(_amountController.text) ?? 0;
    final filteredLines = _lines
        .map((line) => line.toEntity(_statementController.text))
        .where((line) => (line.amount ?? 0) > 0 && line.accountId != null)
        .toList();
    final totalLines = filteredLines.fold<double>(
      0,
      (sum, line) => sum + (line.amount ?? 0),
    );

    final voucher = VoucherEntity(
      id: widget.voucher?.id,
      number: int.tryParse(_numberController.text) ?? 0,
      date: _date,
      statement: _statementController.text.trim(),
      amount: filteredLines.isNotEmpty ? totalLines : headerAmount,
      accountId: _accountId!,
      accountName: _accountName,
      type: _type,
      referenceNumber: _referenceController.text.trim(),
      lines: filteredLines,
    );
    await context.read<VouchersCubit>().saveVoucher(voucher);
  }
}
