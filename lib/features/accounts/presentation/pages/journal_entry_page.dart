import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/journal_entry_entity.dart'
    as domain;
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:hasib_lib/form/form_button.dart';
import 'package:hasib_lib/form/form_field.dart';

class JournalEntry {
  final String id;
  final int? accountId;
  final String account;
  final int? currencyId;
  final String currency;
  final double debit;
  final double credit;
  final String notes;

  const JournalEntry({
    required this.id,
    this.accountId,
    required this.account,
    this.currencyId,
    required this.currency,
    required this.debit,
    required this.credit,
    required this.notes,
  });

  JournalEntry copyWith({
    String? id,
    int? accountId,
    String? account,
    int? currencyId,
    String? currency,
    double? debit,
    double? credit,
    String? notes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      account: account ?? this.account,
      currencyId: currencyId ?? this.currencyId,
      currency: currency ?? this.currency,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      notes: notes ?? this.notes,
    );
  }
}

class JournalHeader {
  final String entryNumber;
  final DateTime entryDate;
  final String description;

  const JournalHeader({
    required this.entryNumber,
    required this.entryDate,
    required this.description,
  });

  JournalHeader copyWith({
    String? entryNumber,
    DateTime? entryDate,
    String? description,
  }) {
    return JournalHeader(
      entryNumber: entryNumber ?? this.entryNumber,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
    );
  }
}

class JournalTotals {
  final double debit;
  final double credit;

  const JournalTotals({required this.debit, required this.credit});

  double get difference => (debit - credit).abs();
  bool get isBalanced => difference < 0.01 && debit > 0;
}

class AppTheme {
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF4F46E5);
  static const greenColor = Color(0xFF059669);
  static const redColor = Color(0xFFDC2626);
  static const yellowColor = Color(0xFFD97706);
}



class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final bool balanced;

  const StatusCard({super.key, required this.balanced});

  @override
  Widget build(BuildContext context) {
    final color = balanced ? AppTheme.greenColor : AppTheme.yellowColor;
    final icon = balanced ? Icons.check_circle : Icons.warning;
    final title = balanced ? 'القيد متوازن' : 'القيد غير متوازن بعد';
    final subtitle = balanced
        ? 'يمكنك حفظ القيد، إجمالي المدين يساوي إجمالي الدائن.'
        : 'يجب مساواة إجمالي المدين والدائن قبل الحفظ.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextFieldSelect<T> extends StatelessWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final bool showHint;
  final bool isRequired;
  final String? errorText;

  const TextFieldSelect({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.showHint = false,
    this.isRequired = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: hint,
        errorText: errorText,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      validator: isRequired
          ? (value) => value == null ? 'مطلوب' : null
          : null,
      items: items,
      onChanged: onChanged,
    );
  }
}

class AddEntryModal extends StatefulWidget {
  final JournalEntry? initialEntry;
  final ValueChanged<JournalEntry> onSave;
  final List<AccountEntity> accounts;
  final List<CurrencyEntity> currencies;

  const AddEntryModal({
    super.key,
    this.initialEntry,
    required this.onSave,
    required this.accounts,
    required this.currencies,
  });

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  AccountEntity? _selectedAccount;
  CurrencyEntity? _selectedCurrency;
  String _direction = 'debit';

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    if (entry != null) {
      // Find account by ID if possible, otherwise by name (fallback)
      if (entry.accountId != null) {
        _selectedAccount = widget.accounts.where((a) => a.id == entry.accountId).firstOrNull;
      } else {
        _selectedAccount = widget.accounts.where((a) => a.name == entry.account).firstOrNull;
      }

      // Find currency by ID if possible, otherwise by name/code
      if (entry.currencyId != null) {
        _selectedCurrency = widget.currencies.where((c) => c.id == entry.currencyId).firstOrNull;
      } else {
        _selectedCurrency = widget.currencies.where((c) => c.name == entry.currency).firstOrNull;
      }
      
      _direction = entry.debit > 0 ? 'debit' : 'credit';
      _amountController = TextEditingController(
        text: (entry.debit + entry.credit).toStringAsFixed(2),
      );
      _notesController = TextEditingController(text: entry.notes);
    } else {
      // Default to first currency (usually local currency)
      if (widget.currencies.isNotEmpty) {
        _selectedCurrency = widget.currencies.first;
      }
      _amountController = TextEditingController(text: '0');
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null || _selectedCurrency == null) return;

    final amount = double.parse(_amountController.text);
    final entry = JournalEntry(
      id:
          widget.initialEntry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: _selectedAccount!.id,
      account: _selectedAccount!.name,
      currencyId: _selectedCurrency!.id,
      currency: _selectedCurrency!.name,
      debit: _direction == 'debit' ? amount : 0,
      credit: _direction == 'credit' ? amount : 0,
      notes: _notesController.text,
    );
    widget.onSave(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialEntry == null
                          ? 'إضافة تفصيل جديد'
                          : 'تعديل تفصيل القيد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'قم بتعبئة البيانات التالية لإضافة سطر جديد إلى القيد.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFieldSelect<AccountEntity>(
                      hint: 'الحساب',
                      items: widget.accounts
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.code} - ${e.name}'),
                              ))
                          .toList(),
                      selectedValue: _selectedAccount,
                      onChanged: (value) =>
                          setState(() => _selectedAccount = value),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextInputField(
                            label: 'المبلغ',
                            inputType: TextInputType.number,
                            textEditingController: _amountController,
                            isRequired: true,
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'الرجاء إدخال مبلغ صحيح';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFieldSelect<CurrencyEntity>(
                            hint: 'العملة',
                            items: widget.currencies
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e.name),
                                    ))
                                .toList(),
                            selectedValue: _selectedCurrency,
                            onChanged: (value) =>
                                setState(() => _selectedCurrency = value),
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DirectionChip(
                            label: 'مدين',
                            selected: _direction == 'debit',
                            color: AppTheme.greenColor,
                            onTap: () => setState(() => _direction = 'debit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DirectionChip(
                            label: 'دائن',
                            selected: _direction == 'credit',
                            color: AppTheme.redColor,
                            onTap: () => setState(() => _direction = 'credit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      label: 'ملاحظات',
                      textEditingController: _notesController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: HasibButton(
                        label: 'إلغاء',
                        onPressed: () => Navigator.of(context).pop(),
                        variant: HasibButtonVariant.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HasibButton(
                        label: widget.initialEntry == null ? 'إضافة' : 'تحديث',
                        onPressed: _submit,
                        variant: HasibButtonVariant.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          color: selected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    
    // Load accounts and currencies
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
      builder: (_) => AlertDialog(
        title: const Text('حذف السطر'),
        content: const Text('هل تريد حذف هذا السطر من القيد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _entries.removeWhere((e) => e.id == entry.id);
              });
              Navigator.of(context).pop();
              _showToast('تم حذف السطر');
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.redColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.greenColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  domain.JournalEntryEntity _buildDomainEntry(JournalTotals totals) {
    final lines = _entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final line = entry.value;
      
      // Find account code if possible
      String? accountCode;
      if (line.accountId != null) {
        final account = _accounts.where((a) => a.id == line.accountId).firstOrNull;
        accountCode = account?.code;
      }
      
      // Find currency code if possible
      String? currencyCode = line.currency;
      if (line.currencyId != null) {
        final currency = _currencies.where((c) => c.id == line.currencyId).firstOrNull;
        if (currency != null) {
          currencyCode = currency.code; // Assuming CurrencyEntity has code
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
      // Manual journal entry should be posted by default so it appears in reports/ledger.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء موازنة القيد قبل الحفظ!'),
          backgroundColor: AppTheme.redColor,
        ),
      );
      return;
    }

    final entity = _buildDomainEntry(totals);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحفظ'),
        content: const Text('هل تريد حفظ القيد المحاسبي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isSaving = true);
              context.read<JournalEntryCubit>().saveEntry(entity);
            },
            child: const Text('حفظ'),
          ),
        ],
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
      builder: (_) => AlertDialog(
        title: const Text('تأكيد المسح'),
        content: const Text('هل تريد مسح جميع تفاصيل القيد الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
              _showToast('تمت إعادة تعيين تفاصيل القيد');
            },
            child: const Text(
              'مسح الكل',
              style: TextStyle(color: AppTheme.redColor),
            ),
          ),
        ],
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.redColor,
              ),
            );
          } else if (state is JournalEntryFormDataLoaded) {
            setState(() {
              _accounts = state.accounts;
              _currencies = state.currencies;
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text('القيود اليومية'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات القيد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل القيد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_entries.length} سطر',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'لم يتم إضافة أي تفصيل بعد',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اضغط على زر الإضافة في الأسفل لإدخال سطر جديد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص القيد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'إجمالي المدين',
                    value: totals.debit.toStringAsFixed(2),
                    backgroundColor: AppTheme.greenColor.withOpacity(0.1),
                    textColor: AppTheme.greenColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'إجمالي الدائن',
                    value: totals.credit.toStringAsFixed(2),
                    backgroundColor: AppTheme.redColor.withOpacity(0.1),
                    textColor: AppTheme.redColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'الفرق',
                    value: totals.difference.toStringAsFixed(2),
                    backgroundColor: AppTheme.yellowColor.withOpacity(0.1),
                    textColor: AppTheme.yellowColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatusCard(balanced: totals.isBalanced),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HasibButton(
                    label: _isSaving ? 'جارٍ الحفظ...' : 'حفظ القيد',
                    onPressed: (_isSaving || !totals.isBalanced)
                        ? null
                        : _saveJournal,
                    variant: HasibButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HasibButton(
                    label: 'مسح القيد',
                    onPressed: _isSaving ? null : _clearAll,
                    variant: HasibButtonVariant.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.account,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'العملة: ${entry.currency}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.notes,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'مدين: ${entry.debit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.greenColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'دائن: ${entry.credit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.redColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'duplicate':
                  onDuplicate();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'duplicate', child: Text('نسخ')),
              PopupMenuItem(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
    );
  }
}
