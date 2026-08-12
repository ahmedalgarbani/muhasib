import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/opening_balance_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';

part 'open_balance_widgets.dart';

class OpeningBalanceApp extends StatelessWidget {
  const OpeningBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<OpeningBalanceCubit>()..initializeForm(),
        ),
        BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAllAccounts()),
      ],
      child: const OpeningBalancePage(),
    );
  }
}

class OpeningBalancePage extends StatefulWidget {
  const OpeningBalancePage({super.key});

  @override
  State<OpeningBalancePage> createState() => _OpeningBalancePageState();
}

class _OpeningBalancePageState extends State<OpeningBalancePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _numberFormat = intl.NumberFormat('#,##0.00', 'ar');

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocConsumer<OpeningBalanceCubit, OpeningBalanceState>(
        listener: (context, state) {
          if (state is OpeningBalanceError) {
            AppToast.showError(context, state.message);
          } else if (state is OpeningBalanceSaved) {
            AppToast.showSuccess(context, 'تم حفظ الرصيد الافتتاحي بنجاح');
            context.read<OpeningBalanceCubit>().initializeForm();
          } else if (state is OpeningBalancePosted) {
            AppToast.showSuccess(
              context,
              'تم ترحيل الرصيد الافتتاحي واعتماده بنجاح',
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<OpeningBalanceCubit>();
          final opening = cubit.currentOpeningBalance;

          if (state is OpeningBalanceLoading || opening == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          _descriptionController.text = opening.description ?? '';
          _notesController.text = opening.notes ?? '';

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: CustomAppBar(
              title: 'الأرصدة الافتتاحية',
              actions: [
                if (opening.id != null)
                  IconButton(
                    onPressed: () => _confirmPost(context, cubit),
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'ترحيل القيد',
                  ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildMasterDataCard(context, opening),
                          const SizedBox(height: 20),
                          _buildSummaryCard(opening),
                          const SizedBox(height: 24),
                          _buildLinesHeader(context),
                          const SizedBox(height: 12),
                          _buildLinesList(context, opening),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(context, opening),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasterDataCard(
    BuildContext context,
    OpeningBalanceEntity opening,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    const Text(
                      'رقم القيد الافتتاحي',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opening.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context, opening),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تاريخ العملية',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            intl.DateFormat(
                              'yyyy/MM/dd',
                            ).format(opening.entryDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          TextInputField(
            label: 'مسمى القيد أو البيان العام',
            textEditingController: _descriptionController,
            prefixIcon: const Icon(Icons.description_outlined),
            onChanged: (v) => context
                .read<OpeningBalanceCubit>()
                .updateFormData(description: v),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(OpeningBalanceEntity opening) {
    final isBalanced = opening.isBalanced;
    final diff = (opening.totalDebit - opening.totalCredit).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isBalanced ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat(
                'إجمالي المدين',
                _numberFormat.format(opening.totalDebit),
                Colors.green,
              ),
              _buildSimpleStat(
                'إجمالي الدائن',
                _numberFormat.format(opening.totalCredit),
                Colors.red,
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 20,
                color: isBalanced ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isBalanced
                    ? 'القيد متوازن حالياً'
                    : 'القيد غير متوازن (الفرق: ${_numberFormat.format(diff)})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isBalanced ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLinesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'توزيع الأرصدة على الحسابات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        HasibButton(
          label: 'إضافة مبلغ',
          leading: const Icon(Icons.add_circle, size: 18, color: Colors.white),
          onPressed: () => _showAddLineDialog(context),
          variant: HasibButtonVariant.primary,
        ),
      ],
    );
  }

  Widget _buildLinesList(BuildContext context, OpeningBalanceEntity opening) {
    if (opening.lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg20),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text(
              'لا توجد أرصدة مضافة بعد',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: opening.lines.asMap().entries.map((entry) {
        final i = entry.key;
        final line = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                line.lineNumber.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(
              line.accountName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                if (line.debit > 0)
                  _badge(
                    'مدين',
                    _numberFormat.format(line.debit),
                    Colors.green,
                  ),
                if (line.credit > 0)
                  _badge('دائن', _numberFormat.format(line.credit), Colors.red),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_note_outlined,
                    color: Colors.blue,
                  ),
                  onPressed: () =>
                      _showAddLineDialog(context, line: line, index: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      context.read<OpeningBalanceCubit>().removeLine(i),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    OpeningBalanceEntity opening,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: HasibButton(
              label: 'حفظ المسودة',
              onPressed: opening.lines.isEmpty
                  ? null
                  : () => context
                        .read<OpeningBalanceCubit>()
                        .saveOpeningBalance(),
              variant: HasibButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLineDialog(
    BuildContext context, {
    OpeningBalanceLineEntity? line,
    int? index,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBalanceLineSheet(
        onAdd: (newLine) {
          if (index != null) {
            context.read<OpeningBalanceCubit>().updateLine(index, newLine);
          } else {
            context.read<OpeningBalanceCubit>().addLine(newLine);
          }
        },
        currencyId: context
            .read<OpeningBalanceCubit>()
            .currentOpeningBalance!
            .currencyId,
        currencyCode: context
            .read<OpeningBalanceCubit>()
            .currentOpeningBalance!
            .currencyCode,
        nextNumber:
            line?.lineNumber ??
            (context
                    .read<OpeningBalanceCubit>()
                    .currentOpeningBalance!
                    .lines
                    .length +
                1),
        existingLine: line,
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    OpeningBalanceEntity opening,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: opening.entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      context.read<OpeningBalanceCubit>().updateFormData(entryDate: picked);
    }
  }

  void _confirmPost(BuildContext context, OpeningBalanceCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: 'تأكيد الترحيل',
        message:
            'عند ترحيل الرصيد الافتتاحي، سيتم تعميد المبالغ في الحسابات ولن تتمكن من تعديل القيد لاحقاً. هل أنت متأكد؟',
        confirmLabel: 'نعم، ترحيل الآن',
        onConfirm: () => cubit.postCurrentOpeningBalance(),
      ),
    );
  }
}
