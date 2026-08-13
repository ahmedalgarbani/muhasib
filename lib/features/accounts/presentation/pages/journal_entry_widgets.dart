part of 'journal_entry_page.dart';

class JournalHeaderCardWidget extends StatelessWidget {
  final TextEditingController numberController;
  final TextEditingController descriptionController;
  final JournalHeader header;
  final ValueChanged<JournalHeader> onHeaderChanged;
  final ValueChanged<DateTime> onDateSelected;

  const JournalHeaderCardWidget({
    super.key,
    required this.numberController,
    required this.descriptionController,
    required this.header,
    required this.onHeaderChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات القيد', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'رقم القيد',
                    textEditingController: numberController,
                    onChanged: (value) =>
                        onHeaderChanged(header.copyWith(entryNumber: value)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: header.entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        onDateSelected(picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ القيد',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${header.entryDate.year}-${header.entryDate.month.toString().padLeft(2, '0')}-${header.entryDate.day.toString().padLeft(2, '0')}',
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
              textEditingController: descriptionController,
              maxLines: 3,
              hint: 'أدخل وصفاً مختصراً للقيد...',
              onChanged: (value) =>
                  onHeaderChanged(header.copyWith(description: value)),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntriesCardWidget extends StatelessWidget {
  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry?> onShowEntryDialog;
  final ValueChanged<JournalEntry> onDuplicateEntry;
  final ValueChanged<JournalEntry> onDeleteEntry;

  const JournalEntriesCardWidget({
    super.key,
    required this.entries,
    required this.onShowEntryDialog,
    required this.onDuplicateEntry,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
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
                    '${entries.length} سطر',
                    style: const TextStyle(
                      color: AppColors.darkSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              height: 24,
              color: AppColors.slate100,
              thickness: 1.5,
            ),
            if (entries.isEmpty)
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
                      padding: AppConstant.defaultPadding,
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
                children: entries
                    .map(
                      (entry) => _EntryTile(
                        entry: entry,
                        onEdit: () => onShowEntryDialog(entry),
                        onDuplicate: () => onDuplicateEntry(entry),
                        onDelete: () => onDeleteEntry(entry),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class JournalSummaryCardWidget extends StatelessWidget {
  final JournalTotals totals;
  final bool isSaving;
  final VoidCallback onSaveJournal;
  final VoidCallback onClearAll;

  const JournalSummaryCardWidget({
    super.key,
    required this.totals,
    required this.isSaving,
    required this.onSaveJournal,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
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
                    label: isSaving ? 'جارٍ الحفظ...' : 'حفظ القيد المحاسبي',
                    onPressed: (isSaving || !totals.isBalanced)
                        ? null
                        : onSaveJournal,
                    variant: HasibButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: isSaving ? null : onClearAll,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: AppConstant.defaultPadding,
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

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = label.contains('مدين');
    final isCredit = label.contains('دائن');

    Color cardBg;
    Color iconBg;
    Color borderCol;

    if (isDebit) {
      cardBg = AppColors.emerald50;
      iconBg = AppColors.emerald100;
      borderCol = AppColors.emerald200;
    } else if (isCredit) {
      cardBg = AppColors.rose50;
      iconBg = AppColors.rose100;
      borderCol = AppColors.red200;
    } else {
      cardBg = AppColors.sky50;
      iconBg = AppColors.sky100;
      borderCol = AppColors.sky200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
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
    final cardBg = balanced ? AppColors.emerald50 : AppColors.amber50;
    final borderCol = balanced
        ? AppColors.emerald200
        : AppColors.amber200;
    final color = balanced ? AppColors.emerald700 : AppColors.amber700;
    final icon = balanced
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;
    final title = balanced ? 'القيد متوازن' : 'القيد غير متوازن';
    final subtitle = balanced
        ? 'المدين يساوي الدائن تماماً. يمكنك حفظ القيد الآن.'
        : 'إجمالي المبالغ المدينة لا تتساوى مع الدائنة. يرجى المراجعة.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderCol, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      if (entry.accountId != null) {
        _selectedAccount = widget.accounts
            .where((a) => a.id == entry.accountId)
            .firstOrNull;
      } else {
        _selectedAccount = widget.accounts
            .where((a) => a.name == entry.account)
            .firstOrNull;
      }

      if (entry.currencyId != null) {
        _selectedCurrency = widget.currencies
            .where((c) => c.id == entry.currencyId)
            .firstOrNull;
      } else {
        _selectedCurrency = widget.currencies
            .where((c) => c.name == entry.currency)
            .firstOrNull;
      }

      _direction = entry.debit > 0 ? 'debit' : 'credit';
      _amountController = TextEditingController(
        text: (entry.debit + entry.credit).toStringAsFixed(2),
      );
      _notesController = TextEditingController(text: entry.notes);
    } else {
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
    return CustomDialog(
      title: widget.initialEntry == null ? 'إضافة تفصيل جديد' : 'تعديل تفصيل القيد',
      subtitle: 'قم بتعبئة البيانات التالية لإضافة سطر جديد إلى القيد.',
      icon: Icons.post_add_rounded,
      headerColor: AppTheme.primaryColor,
      maxWidth: 480,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomDropdownField<AccountEntity>(
              hint: 'الحساب',
              items: widget.accounts
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text('${e.code} - ${e.name}'),
                    ),
                  )
                  .toList(),
              value: _selectedAccount,
              onChanged: (value) => setState(() => _selectedAccount = value),
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
                  child: CustomDropdownField<CurrencyEntity>(
                    hint: 'العملة',
                    items: widget.currencies
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    value: _selectedCurrency,
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
      actions: [
        HasibButton(
          label: 'إلغاء',
          onPressed: () => Navigator.of(context).pop(),
          variant: HasibButtonVariant.secondary,
        ),
        const SizedBox(width: 12),
        HasibButton(
          label: widget.initialEntry == null ? 'إضافة' : 'تحديث',
          onPressed: _submit,
          variant: HasibButtonVariant.primary,
        ),
      ],
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? color : AppColors.borderLight,
            width: 1.5,
          ),
          color: selected ? color.withOpacity(0.08) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? color : AppColors.textSecondaryDark,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? color : AppColors.darkSecondary,
              ),
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
    final isDebitDominant = entry.debit > entry.credit;
    final accentColor = isDebitDominant
        ? AppColors.success
        : AppColors.error;
    final softAccentColor = isDebitDominant
        ? AppColors.emerald100
        : AppColors.red100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.slate100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: accentColor, width: 5)),
          ),
          padding: AppConstant.defaultPadding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: softAccentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebitDominant
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.account,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(AppRadius.sm6),
                          ),
                          child: Text(
                            entry.currency,
                            style: const TextStyle(
                              color: AppColors.darkSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (entry.notes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.debit > 0)
                    Text(
                      'مدين: ${entry.debit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  if (entry.credit > 0)
                    Text(
                      'دائن: ${entry.credit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
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
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
