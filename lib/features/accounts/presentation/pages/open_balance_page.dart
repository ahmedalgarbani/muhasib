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
            _showSnack(state.message, isError: true);
          } else if (state is OpeningBalanceSaved) {
            _showSnack('تم حفظ الرصيد الافتتاحي بنجاح');
            context.read<OpeningBalanceCubit>().initializeForm();
          } else if (state is OpeningBalancePosted) {
            _showSnack('تم ترحيل الرصيد الافتتاحي واعتماده بنجاح');
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
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                'الأرصدة الافتتاحية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.gradientPrimary),
                ),
              ),
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
        borderRadius: BorderRadius.circular(24),
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
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'مسمى القيد أو البيان العام',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        borderRadius: BorderRadius.circular(24),
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
        ElevatedButton.icon(
          onPressed: () => _showAddLineDialog(context),
          icon: const Icon(Icons.add_circle, size: 18),
          label: const Text('إضافة مبلغ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
          borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(6),
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: opening.lines.isEmpty
                  ? null
                  : () => context
                        .read<OpeningBalanceCubit>()
                        .saveOpeningBalance(),
              child: const Text(
                'حفظ المسودة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
    if (picked != null)
      context.read<OpeningBalanceCubit>().updateFormData(entryDate: picked);
  }

  void _confirmPost(BuildContext context, OpeningBalanceCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الترحيل'),
        content: const Text(
          'عند ترحيل الرصيد الافتتاحي، سيتم تعميد المبالغ في الحسابات ولن تتمكن من تعديل القيد لاحقاً. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.postCurrentOpeningBalance();
            },
            child: const Text('نعم، ترحيل الآن'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _AddBalanceLineSheet extends StatefulWidget {
  final Function(OpeningBalanceLineEntity) onAdd;
  final int currencyId;
  final String currencyCode;
  final int nextNumber;
  final OpeningBalanceLineEntity? existingLine;

  const _AddBalanceLineSheet({
    required this.onAdd,
    required this.currencyId,
    required this.currencyCode,
    required this.nextNumber,
    this.existingLine,
  });

  @override
  State<_AddBalanceLineSheet> createState() => _AddBalanceLineSheetState();
}

class _AddBalanceLineSheetState extends State<_AddBalanceLineSheet> {
  AccountEntity? _selectedAccount;
  final _amountController = TextEditingController();
  bool _isDebit = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingLine != null) {
      _isDebit = widget.existingLine!.debit > 0;
      _amountController.text =
          (_isDebit ? widget.existingLine!.debit : widget.existingLine!.credit)
              .toString();
      _selectedAccount = AccountEntity(
        id: widget.existingLine!.accountId,
        code: widget.existingLine!.accountCode,
        name: widget.existingLine!.accountName,
        isMaster: false,
        cId: 0,
        type: 0,
        national: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة رصيد حساب',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text(
                  'اختر الحساب',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildAccountPicker(context),
                const SizedBox(height: 24),
                const Text(
                  'نوع الرصيد',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildTypeSelector(),
                const SizedBox(height: 24),
                const Text(
                  'قيمة الرصيد',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'إضافة للجدول',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPicker(BuildContext context) {
    return InkWell(
      onTap: () => _pickAccount(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedAccount?.name ?? 'اضغط لاختيار الحساب المالي...',
              style: TextStyle(
                color: _selectedAccount == null ? Colors.grey : Colors.black87,
                fontWeight: _selectedAccount != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            const Icon(Icons.search, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeBtn('مدين (+) ', true, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _typeBtn('دائن (-) ', false, Colors.red)),
      ],
    );
  }

  Widget _typeBtn(String label, bool value, Color color) {
    final active = _isDebit == value;
    return GestureDetector(
      onTap: () => setState(() => _isDebit = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  void _pickAccount(BuildContext context) {
    // I'll show the search sheet here
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimpleAccountSelector(
        onSelected: (acc) => setState(() => _selectedAccount = acc),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_selectedAccount == null || amount <= 0) return;

    widget.onAdd(
      OpeningBalanceLineEntity(
        lineNumber: widget.nextNumber,
        accountId: _selectedAccount!.id!,
        accountCode: _selectedAccount!.code,
        accountName: _selectedAccount!.name,
        currencyId: widget.currencyId,
        currencyCode: widget.currencyCode,
        debit: _isDebit ? amount : 0,
        credit: _isDebit ? 0 : amount,
      ),
    );
    Navigator.pop(context);
  }
}

class _SimpleAccountSelector extends StatefulWidget {
  final Function(AccountEntity) onSelected;
  const _SimpleAccountSelector({required this.onSelected});

  @override
  State<_SimpleAccountSelector> createState() => _SimpleAccountSelectorState();
}

class _SimpleAccountSelectorState extends State<_SimpleAccountSelector> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];
    final filtered = accounts
        .where((a) => a.name.contains(_query) || a.code.contains(_query))
        .toList();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن حساب...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(
                    filtered[i].name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(filtered[i].code),
                  onTap: () {
                    widget.onSelected(filtered[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
