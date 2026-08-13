import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart'
    as domain;
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(title: 'القيود اليومية'),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEntryDialog(),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: AppConstant.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JournalHeaderCardWidget(
                  numberController: _numberController,
                  descriptionController: _descriptionController,
                  header: _header,
                  onHeaderChanged: (header) => setState(() => _header = header),
                  onDateSelected: (date) =>
                      setState(() => _header = _header.copyWith(entryDate: date)),
                ),
                const SizedBox(height: 16),
                JournalEntriesCardWidget(
                  entries: _entries,
                  onShowEntryDialog: (entry) => _showEntryDialog(entry: entry),
                  onDuplicateEntry: _duplicateEntry,
                  onDeleteEntry: _deleteEntry,
                ),
                const SizedBox(height: 16),
                JournalSummaryCardWidget(
                  totals: totals,
                  isSaving: _isSaving,
                  onSaveJournal: _saveJournal,
                  onClearAll: _clearAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
