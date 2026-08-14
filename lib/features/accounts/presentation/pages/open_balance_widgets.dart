part of 'open_balance_page.dart';

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
  bool _isSolo = false;

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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة رصيد حساب',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (widget.existingLine == null) ...[
                    const SizedBox(height: 20),
                    _OpenBalanceModeSelector(
                      isSolo: _isSolo,
                      onChanged: (v) => setState(() => _isSolo = v),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'اختر الحساب',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OpenBalanceAccountPickerWidget(
                    selectedAccount: _selectedAccount,
                    onTap: () => _pickAccount(context),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'نوع الرصيد',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OpenBalanceTypeSelectorWidget(
                    isDebit: _isDebit,
                    onChanged: (val) => setState(() => _isDebit = val),
                  ),
                  if (_isSolo) ...[
                    const SizedBox(height: 16),
                    const _OpenBalanceSoloHintWidget(),
                  ],
                  const SizedBox(height: 24),
                  TextInputField(
                    label: 'قيمة الرصيد',
                    textEditingController: _amountController,
                    inputType: TextInputType.number,
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    hint: '0.00',
                  ),
                  const SizedBox(height: 32),
                  HasibButton(
                    label: _isSolo ? 'إضافة بموازنة تلقائية' : 'إضافة للجدول',
                    onPressed: _submit,
                    variant: HasibButtonVariant.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickAccount(BuildContext context) {
    final accountsCubit = context.read<AccountsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: accountsCubit,
        child: _SimpleAccountSelector(
          onSelected: (acc) => setState(() => _selectedAccount = acc),
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_selectedAccount == null || amount <= 0) return;

    if (_isSolo) {
      _submitSolo(amount);
      return;
    }

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

  void _submitSolo(double amount) {
    final counterpart = _findCounterpartAccount();
    if (counterpart == null) {
      AppToast.showError(
        context,
        'لم يتم العثور على حساب الأرصدة الافتتاحية لموازنة القيد',
      );
      return;
    }

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
        notes: _isDebit ? 'من حـ' : 'إلى حـ',
      ),
    );
    widget.onAdd(
      OpeningBalanceLineEntity(
        lineNumber: widget.nextNumber + 1,
        accountId: counterpart.id!,
        accountCode: counterpart.code,
        accountName: counterpart.name,
        currencyId: widget.currencyId,
        currencyCode: widget.currencyCode,
        debit: _isDebit ? 0 : amount,
        credit: _isDebit ? amount : 0,
        notes: _isDebit ? 'إلى حـ' : 'من حـ',
      ),
    );
    Navigator.pop(context);
  }

  AccountEntity? _findCounterpartAccount() {
    final accounts = context.read<AccountsCubit>().allAccounts ?? [];
    for (final account in accounts) {
      if (account.code == '3100' || account.name.contains('أرصدة افتتاحية')) {
        return account;
      }
    }
    for (final account in accounts) {
      if (account.code == '2002' || account.name.contains('رأس المال')) {
        return account;
      }
    }
    return null;
  }
}

class _OpenBalanceModeSelector extends StatelessWidget {
  final bool isSolo;
  final ValueChanged<bool> onChanged;

  const _OpenBalanceModeSelector({
    required this.isSolo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OpenBalanceModeButton(
            label: 'حساب فردي',
            icon: Icons.person_outline,
            selected: isSolo,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OpenBalanceModeButton(
            label: 'مجموعة حسابات',
            icon: Icons.account_tree_outlined,
            selected: !isSolo,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _OpenBalanceModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OpenBalanceModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenBalanceSoloHintWidget extends StatelessWidget {
  const _OpenBalanceSoloHintWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'سيتم إضافة السطر المقابل تلقائياً على حساب الأرصدة الافتتاحية لموازنة القيد.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenBalanceAccountPickerWidget extends StatelessWidget {
  final AccountEntity? selectedAccount;
  final VoidCallback onTap;

  const OpenBalanceAccountPickerWidget({
    super.key,
    required this.selectedAccount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppConstant.defaultPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              selectedAccount?.name ?? 'اضغط لاختيار الحساب المالي...',
              style: TextStyle(
                color: selectedAccount == null
                    ? Colors.grey
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: selectedAccount != null
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
}

class OpenBalanceTypeSelectorWidget extends StatelessWidget {
  final bool isDebit;
  final ValueChanged<bool> onChanged;

  const OpenBalanceTypeSelectorWidget({
    super.key,
    required this.isDebit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpenBalanceTypeButtonWidget(
            label: 'مدين (+) ',
            value: true,
            color: Colors.green,
            isDebit: isDebit,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OpenBalanceTypeButtonWidget(
            label: 'دائن (-) ',
            value: false,
            color: Colors.red,
            isDebit: isDebit,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class OpenBalanceTypeButtonWidget extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final bool isDebit;
  final VoidCallback onTap;

  const OpenBalanceTypeButtonWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDebit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isDebit == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? color : Theme.of(context).dividerColor,
          ),
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
}

class _SimpleAccountSelector extends StatefulWidget {
  final Function(AccountEntity) onSelected;
  const _SimpleAccountSelector({required this.onSelected});

  @override
  State<_SimpleAccountSelector> createState() => _SimpleAccountSelectorState();
}

class _SimpleAccountSelectorState extends State<_SimpleAccountSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xxs),
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
                  TextInputField(
                    hint: 'ابحث عن حساب...',
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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

  Widget _buildList(List<AccountEntity> accounts, String? filter) {
    final filtered = accounts.where((a) {
      final matchSearch = a.name.contains(_query) || a.code.contains(_query);
      if (filter == null) return matchSearch;
      return matchSearch && a.name.contains(filter);
    }).toList();

    return ListView.builder(
      padding: AppConstant.defaultPadding,
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
    );
  }
}
