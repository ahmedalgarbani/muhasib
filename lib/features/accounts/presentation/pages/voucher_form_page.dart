import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import '../cubit/vouchers_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: widget.voucher == null
                ? 'إضافة ${_type.label}'
                : 'تعديل ${_type.label}',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VoucherFormTopSectionWidget(
                    numberController: _numberController,
                    date: _date,
                    type: _type,
                    onPickDate: _pickDate,
                    onTypeChanged: (newType) {
                      setState(() => _type = newType);
                      if (widget.voucher == null) {
                        context.read<VouchersCubit>().refreshNumber(_type);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  VoucherFormAccountAndAmountWidget(
                    accountName: _accountName,
                    amountController: _amountController,
                    onPickAccount: () => _pickAccount(isLine: false),
                  ),
                  const SizedBox(height: 10),
                  VoucherFormStatementFieldWidget(
                    typeLabel: _type.label,
                    statementController: _statementController,
                  ),
                  const SizedBox(height: 12),
                  VoucherFormLinesSectionWidget(
                    lines: _lines,
                    headerAmount: double.tryParse(_amountController.text) ?? 0,
                    onAddLine: () =>
                        setState(() => _lines.add(_VoucherLineInput())),
                    onPickLineAccount: (i) =>
                        _pickAccount(isLine: true, lineIndex: i),
                    onRemoveLine: (i) =>
                        setState(() => _lines.removeAt(i).dispose()),
                    onSyncHeaderAmount: (total) {
                      setState(() {
                        _amountController.text = total.toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  VoucherFormSaveButtonWidget(onSave: _onSave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickAccount({required bool isLine, int? lineIndex}) {
    final accountsCubit = context.read<AccountsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (modalContext) => BlocProvider.value(
        value: accountsCubit,
        child: _AccountSelectorSheet(
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
      AppToast.showError(
        context,
        'يجب اختيار الحساب الرئيسي (الصندوق / البنك)',
      );
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

    // Validate that lines total matches the voucher header amount
    if (filteredLines.isNotEmpty && (headerAmount - totalLines).abs() > 0.01) {
      AppToast.showError(
        context,
        'مجموع بنود السند (${totalLines.toStringAsFixed(2)}) لا يتطابق مع المبلغ الإجمالي (${headerAmount.toStringAsFixed(2)})!\nيرجى موازنة المبالغ أو تعديل الإجمالي.',
      );
      return;
    }

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

class VoucherFormTopSectionWidget extends StatelessWidget {
  final TextEditingController numberController;
  final DateTime date;
  final VoucherType type;
  final VoidCallback onPickDate;
  final ValueChanged<VoucherType> onTypeChanged;

  const VoucherFormTopSectionWidget({
    super.key,
    required this.numberController,
    required this.date,
    required this.type,
    required this.onPickDate,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  label: 'رقم السند',
                  textEditingController: numberController,
                  inputType: TextInputType.number,
                  validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
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
                      onTap: onPickDate,
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
                              DateFormatter.formatDate(date),
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
          VoucherFormTypeToggleWidget(type: type, onTypeChanged: onTypeChanged),
        ],
      ),
    );
  }
}

class VoucherFormTypeToggleWidget extends StatelessWidget {
  final VoucherType type;
  final ValueChanged<VoucherType> onTypeChanged;

  const VoucherFormTypeToggleWidget({
    super.key,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm14),
      ),
      child: Row(
        children: [
          Expanded(
            child: VoucherFormToggleButtonWidget(
              targetType: VoucherType.receipt,
              label: 'سند قبض',
              icon: Icons.call_received,
              currentType: type,
              onTap: () => onTypeChanged(VoucherType.receipt),
            ),
          ),
          Expanded(
            child: VoucherFormToggleButtonWidget(
              targetType: VoucherType.payment,
              label: 'سند صرف',
              icon: Icons.call_made,
              currentType: type,
              onTap: () => onTypeChanged(VoucherType.payment),
            ),
          ),
        ],
      ),
    );
  }
}

class VoucherFormToggleButtonWidget extends StatelessWidget {
  final VoucherType targetType;
  final String label;
  final IconData icon;
  final VoucherType currentType;
  final VoidCallback onTap;

  const VoucherFormToggleButtonWidget({
    super.key,
    required this.targetType,
    required this.label,
    required this.icon,
    required this.currentType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentType == targetType;
    final color = targetType == VoucherType.receipt ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
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
}

class VoucherFormAccountAndAmountWidget extends StatelessWidget {
  final String? accountName;
  final TextEditingController amountController;
  final VoidCallback onPickAccount;

  const VoucherFormAccountAndAmountWidget({
    super.key,
    required this.accountName,
    required this.amountController,
    required this.onPickAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Theme.of(context).dividerColor),
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
            selectedAccountName: accountName,
            onTap: onPickAccount,
          ),
          const SizedBox(height: 16),
          const Text(
            'المبلغ الإجمالي',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          TextInputField(
            textEditingController: amountController,
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
}

class VoucherFormStatementFieldWidget extends StatelessWidget {
  final String typeLabel;
  final TextEditingController statementController;

  const VoucherFormStatementFieldWidget({
    super.key,
    required this.typeLabel,
    required this.statementController,
  });

  @override
  Widget build(BuildContext context) {
    return TextInputField(
      label: 'البيان العام لسند $typeLabel',
      textEditingController: statementController,
      maxLines: 2,
      prefixIcon: const Icon(Icons.description_outlined),
      validator: (value) => (value?.isEmpty ?? true) ? 'البيان مطلوب' : null,
    );
  }
}

class VoucherFormLinesSectionWidget extends StatelessWidget {
  final List<_VoucherLineInput> lines;
  final double headerAmount;
  final VoidCallback onAddLine;
  final ValueChanged<int> onPickLineAccount;
  final ValueChanged<int> onRemoveLine;
  final ValueChanged<double> onSyncHeaderAmount;

  const VoucherFormLinesSectionWidget({
    super.key,
    required this.lines,
    required this.headerAmount,
    required this.onAddLine,
    required this.onPickLineAccount,
    required this.onRemoveLine,
    required this.onSyncHeaderAmount,
  });

  @override
  Widget build(BuildContext context) {
    final totalLines = lines.fold<double>(
      0,
      (sum, l) => sum + (double.tryParse(l.amountController.text) ?? 0),
    );
    final isMatched =
        lines.isEmpty || (headerAmount - totalLines).abs() <= 0.01;

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
              onPressed: onAddLine,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة سطر'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (lines.isEmpty)
          const Text(
            'في حال عدم إضافة سطور، سيتم توجيه المبلغ بالكامل للحساب الرئيسي المختار أعلاه.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMatched ? AppColors.emerald50 : AppColors.amber50,
              border: Border.all(
                color: isMatched ? AppColors.emerald200 : AppColors.amber200,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  isMatched ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isMatched ? AppColors.emerald700 : AppColors.amber700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMatched
                        ? 'مجموع البنود متطابق: ${totalLines.toStringAsFixed(2)} ريال'
                        : 'مجموع البنود (${totalLines.toStringAsFixed(2)}) لا يطابق الإجمالي (${headerAmount.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMatched
                          ? AppColors.emerald700
                          : AppColors.amber700,
                    ),
                  ),
                ),
                if (!isMatched && totalLines > 0)
                  TextButton(
                    onPressed: () => onSyncHeaderAmount(totalLines),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'مزامنة الإجمالي',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...lines.asMap().entries.map(
          (entry) => VoucherFormLineCardWidget(
            index: entry.key,
            line: entry.value,
            onPickAccount: () => onPickLineAccount(entry.key),
            onRemove: () => onRemoveLine(entry.key),
          ),
        ),
      ],
    );
  }
}

class VoucherFormLineCardWidget extends StatelessWidget {
  final int index;
  final _VoucherLineInput line;
  final VoidCallback onPickAccount;
  final VoidCallback onRemove;

  const VoucherFormLineCardWidget({
    super.key,
    required this.index,
    required this.line,
    required this.onPickAccount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _AccountPickerField(
            selectedAccountName: line.accountName,
            onTap: onPickAccount,
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
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoucherFormSaveButtonWidget extends StatelessWidget {
  final VoidCallback onSave;

  const VoucherFormSaveButtonWidget({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VouchersCubit, VouchersState>(
      builder: (context, state) {
        final saving = state is VoucherActionInProgress;
        return HasibButton(
          label: 'حفظ السند الآن',
          loading: saving,
          onPressed: saving ? null : onSave,
          variant: HasibButtonVariant.primary,
        );
      },
    );
  }
}
