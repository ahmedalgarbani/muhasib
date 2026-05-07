import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import '../cubit/vouchers_cubit.dart';

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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop(true);
          } else if (state is VouchersFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is VoucherNumberGenerated &&
              widget.voucher == null &&
              state.type == _type) {
            _numberController.text = state.number.toString();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              widget.voucher == null
                  ? 'إضافة ${_type.label}'
                  : 'تعديل ${_type.label}',
              style: const TextStyle(
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
        borderRadius: BorderRadius.circular(20),
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
                      'رقم السند',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(14),
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
        if (widget.voucher == null)
          context.read<VouchersCubit>().refreshNumber(_type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(20),
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
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: '0.00',
            ),
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل مبلغ صحيح' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatementField() {
    return TextFormField(
      controller: _statementController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'البيان العام لسند ال${_type.label}',
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.description_outlined),
      ),
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
        borderRadius: BorderRadius.circular(16),
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
                child: TextFormField(
                  controller: line.amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: line.statementController,
                  decoration: InputDecoration(
                    labelText: 'بيان السطر',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            onPressed: saving ? null : _onSave,
            child: saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'حفظ السند الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _pickAccount({required bool isLine, int? lineIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار الحساب الرئيسي')),
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

class _AccountPickerField extends StatelessWidget {
  final String? selectedAccountName;
  final VoidCallback onTap;

  const _AccountPickerField({this.selectedAccountName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedAccountName ?? 'اختر الحساب من القائمة...',
                style: TextStyle(
                  color: selectedAccountName != null
                      ? Colors.black87
                      : Colors.grey,
                  fontWeight: selectedAccountName != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _AccountSelectorSheet extends StatefulWidget {
  final Function(AccountEntity) onSelected;
  const _AccountSelectorSheet({required this.onSelected});

  @override
  State<_AccountSelectorSheet> createState() => _AccountSelectorSheetState();
}

class _AccountSelectorSheetState extends State<_AccountSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'اختيار الحساب',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن حساب...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'الصناديق'),
                Tab(text: 'البنوك'),
                Tab(text: 'العملاء'),
                Tab(text: 'الموردين'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(accounts, null),
                  _buildList(accounts, 'صندوق'),
                  _buildList(accounts, 'بنك'),
                  _buildList(accounts, 'عميل'),
                  _buildList(accounts, 'مورد'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AccountEntity> all, String? filter) {
    var filtered = all.where((a) {
      final matchSearch =
          a.name.contains(_searchQuery) || a.code.contains(_searchQuery);
      if (filter == null) return matchSearch;
      final matchFilter = a.name.contains(filter);
      return matchSearch && matchFilter;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final a = filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            a.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(a.code),
          onTap: () {
            widget.onSelected(a);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _VoucherLineInput {
  _VoucherLineInput({
    this.accountId,
    this.accountName,
    double? amount,
    String? statement,
  }) : amountController = TextEditingController(
         text: amount != null ? amount.toString() : '',
       ),
       statementController = TextEditingController(text: statement ?? '');

  int? accountId;
  String? accountName;
  final TextEditingController amountController;
  final TextEditingController statementController;

  VoucherLineEntity toEntity(String fallbackStatement) {
    final parsedAmount = double.tryParse(amountController.text) ?? 0;
    return VoucherLineEntity(
      accountId: accountId,
      accountName: accountName,
      amount: parsedAmount,
      statement: statementController.text.trim().isEmpty
          ? fallbackStatement
          : statementController.text.trim(),
    );
  }

  void dispose() {
    amountController.dispose();
    statementController.dispose();
  }
}
