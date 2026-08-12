import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart'
    as domain;
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';

part 'journal_entry_models.dart';
part 'journal_entry_widgets.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final List<JournalEntry> _entries = [];

  late TextEditingController _numberController;
  late TextEditingController _descriptionController;

  JournalHeader _header = JournalHeader(
    entryNumber: '',
    entryDate: DateTime.now(),
    description: '',
  );

  bool _isSaving = false;
  List<AccountEntity> _accounts = [];
  List<CurrencyEntity> _currencies = [];

  @override
  void initState() {
    super.initState();
    final generatedNumber = _generateEntryNumber();
    _header = _header.copyWith(entryNumber: generatedNumber);
    _numberController = TextEditingController(text: generatedNumber);
    _descriptionController = TextEditingController();

    context.read<JournalEntryCubit>().loadFormData();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateEntryNumber() {
    final now = DateTime.now();
    return 'JRNL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 1000000}';
  }

  JournalTotals _calculateTotals() {
    double debit = 0;
    double credit = 0;
    for (final entry in _entries) {
      debit += entry.debit;
      credit += entry.credit;
    }
    return JournalTotals(debit: debit, credit: credit);
  }

  void _showEntryDialog({JournalEntry? entry}) {
    if (_accounts.isEmpty || _currencies.isEmpty) {
      _showToast('جاري تحميل البيانات، يرجى الانتظار...');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AddEntryModal(
        initialEntry: entry,
        onSave: entry == null ? _addEntry : _updateEntry,
        accounts: _accounts.where((a) => !a.isMaster).toList(),
        currencies: _currencies,
      ),
    );
  }

  void _addEntry(JournalEntry entry) {
    setState(() {
      _entries.add(entry);
    });
    _showToast('تمت إضافة السطر بنجاح');
  }

  void _updateEntry(JournalEntry entry) {
    setState(() {
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
      }
    });
    _showToast('تم تحديث السطر بنجاح');
  }

  void _duplicateEntry(JournalEntry entry) {
    _addEntry(
      entry.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()),
    );
    _showToast('تم نسخ السطر بنجاح');
  }

  void _deleteEntry(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (_) => CustomConfirmDialog(
        title: 'حذف السطر',
        message: 'هل تريد حذف هذا السطر من القيد؟',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          setState(() {
            _entries.removeWhere((e) => e.id == entry.id);
          });
          AppToast.showSuccess(context, 'تم حذف السطر');
        },
      ),
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.showSuccess(context, message);
  }

  domain.JournalEntryEntity _buildDomainEntry(JournalTotals totals) {
    final lines = _entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final line = entry.value;

      String? accountCode;
      if (line.accountId != null) {
        final account = _accounts
            .where((a) => a.id == line.accountId)
            .firstOrNull;
        accountCode = account?.code;
      }

      String? currencyCode = line.currency;
      if (line.currencyId != null) {
        final currency = _currencies
            .where((c) => c.id == line.currencyId)
            .firstOrNull;
        if (currency != null) {
          currencyCode = currency.code;
        }
      }

      return domain.JournalEntryLineEntity(
        lineNumber: idx + 1,
        accountId: line.accountId,
        accountCode: accountCode,
        accountName: line.account,
        currencyId: line.currencyId,
        currencyCode: currencyCode,
        debit: line.debit,
        credit: line.credit,
        notes: line.notes,
      );
    }).toList();

    final number = _numberController.text.trim().isEmpty
        ? _generateEntryNumber()
        : _numberController.text.trim();

    return domain.JournalEntryEntity(
      number: number,
      entryDate: _header.entryDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isPosted: true,
      totalDebit: totals.debit,
      totalCredit: totals.credit,
      difference: totals.difference,
      lines: lines,
    );
  }

  void _saveJournal() {
    final totals = _calculateTotals();
    if (!totals.isBalanced) {
      AppToast.showError(context, 'برجاء موازنة القيد قبل الحفظ!');
      return;
    }

    final entity = _buildDomainEntry(totals);

    showDialog(
      context: context,
      builder: (_) => CustomConfirmDialog(
        title: 'تأكيد الحفظ',
        message: 'هل تريد حفظ القيد المحاسبي؟',
        confirmLabel: 'حفظ',
        onConfirm: () {
          setState(() => _isSaving = true);
          context.read<JournalEntryCubit>().saveEntry(entity);
        },
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _entries.clear();
      _header = JournalHeader(
        entryNumber: _generateEntryNumber(),
        entryDate: DateTime.now(),
        description: '',
      );
      _numberController.text = _header.entryNumber;
      _descriptionController.clear();
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (_) => CustomConfirmDialog(
        title: 'تأكيد المسح',
        message: 'هل تريد مسح جميع تفاصيل القيد الحالية؟',
        confirmLabel: 'مسح الكل',
        isDanger: true,
        onConfirm: () {
          _resetForm();
          _showToast('تمت إعادة تعيين تفاصيل القيد');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<JournalEntryCubit, JournalEntryState>(
        listener: (context, state) {
          if (state is JournalEntryActionInProgress) {
            setState(() => _isSaving = true);
          } else if (state is JournalEntryActionSuccess) {
            setState(() => _isSaving = false);
            _showToast(state.message);
            _resetForm();
          } else if (state is JournalEntryFailure) {
            setState(() => _isSaving = false);
            AppToast.showError(context, state.message);
          } else if (state is JournalEntryFormDataLoaded) {
            setState(() {
              _accounts = state.accounts;
              _currencies = state.currencies;
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: CustomAppBar(
            title: 'القيود اليومية',
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEntryDialog(),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildEntriesCard(),
                const SizedBox(height: 16),
                _buildSummaryCard(totals),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات القيد',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'رقم القيد',
                    textEditingController: _numberController,
                    onChanged: (value) =>
                        _header = _header.copyWith(entryNumber: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _header.entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _header = _header.copyWith(entryDate: picked);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ القيد',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_header.entryDate.year}-${_header.entryDate.month.toString().padLeft(2, '0')}-${_header.entryDate.day.toString().padLeft(2, '0')}',
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextInputField(
              label: 'وصف القيد',
              textEditingController: _descriptionController,
              maxLines: 3,
              hint: 'أدخل وصفاً مختصراً للقيد...',
              onChanged: (value) =>
                  _header = _header.copyWith(description: value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: AppColors.slate100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل القيد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppRadius.sm10),
                  ),
                  child: Text(
                    '${_entries.length} سطر',
                    style: const TextStyle(
                      color: AppColors.darkSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.slate100, thickness: 1.5),
            if (_entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.blue50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 36,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لم يتم إضافة أي تفصيل بعد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اضغط على زر الإضافة الدائري بالأسفل لإضافة سطر جديد للقيد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _entries
                    .map(
                      (entry) => _EntryTile(
                        entry: entry,
                        onEdit: () => _showEntryDialog(entry: entry),
                        onDuplicate: () => _duplicateEntry(entry),
                        onDelete: () => _deleteEntry(entry),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(JournalTotals totals) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm10),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ملخص القيد والتحقق',
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'إجمالي المدين',
                    value: totals.debit.toStringAsFixed(2),
                    color: AppTheme.greenColor,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'إجمالي الدائن',
                    value: totals.credit.toStringAsFixed(2),
                    color: AppTheme.redColor,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SummaryCard(
              label: 'الفرق المحاسبي',
              value: totals.difference.toStringAsFixed(2),
              color: totals.isBalanced
                  ? AppTheme.greenColor
                  : AppTheme.redColor,
              icon: Icons.balance,
            ),
            const SizedBox(height: 20),
            StatusCard(balanced: totals.isBalanced),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: HasibButton(
                    label: _isSaving ? 'جارٍ الحفظ...' : 'حفظ القيد المحاسبي',
                    onPressed: (_isSaving || !totals.isBalanced)
                        ? null
                        : _saveJournal,
                    variant: HasibButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSaving ? null : _clearAll,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
