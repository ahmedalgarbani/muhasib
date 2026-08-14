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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    context.read<AccountsCubit>().loadAllAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static bool _matchesCategory(AccountEntity a, int categoryIndex) {
    final name = a.name.toLowerCase();
    final statement = (a.statement ?? '').toLowerCase();

    final isBank =
        (a.masterCId == 1110 &&
            (name.contains('بنك') ||
                name.contains('مصرف') ||
                statement.contains('بنك') ||
                statement.contains('مصرف'))) ||
        name.contains('بنك') ||
        name.contains('مصرف') ||
        name.contains('bank') ||
        statement.contains('بنك');

    final isCash =
        (a.masterCId == 1110 && !isBank) ||
        name.contains('صندوق') ||
        name.contains('خزينة') ||
        name.contains('كاش') ||
        name.contains('نقد') ||
        name.contains('درج') ||
        statement.contains('صندوق') ||
        statement.contains('خزينة');

    final isCustomer =
        a.masterCId == 1120 ||
        a.cId == 1120 ||
        a.code.startsWith('112') ||
        a.code.startsWith('1002') ||
        statement.contains('عميل') ||
        statement.contains('العملاء') ||
        name.contains('عميل') ||
        (a.type == 1 && a.cId >= 112000 && a.cId < 113000);

    final isSupplier =
        a.masterCId == 2110 ||
        a.cId == 2110 ||
        a.code.startsWith('211') ||
        a.code.startsWith('2001') ||
        statement.contains('مورد') ||
        statement.contains('الموردون') ||
        statement.contains('الموردين') ||
        name.contains('مورد') ||
        (a.type == 2 && a.cId >= 211000 && a.cId < 212000);

    switch (categoryIndex) {
      case 0: // الكل
        return true;
      case 1: // الصناديق
        return isCash;
      case 2: // البنوك
        return isBank;
      case 3: // العملاء
        return isCustomer;
      case 4: // الموردين
        return isSupplier;
      case 5: // أخرى
        return !isCash && !isBank && !isCustomer && !isSupplier;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'اختيار الحساب المحاسبي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'تحديث الحسابات',
                        onPressed: () {
                          context.read<AccountsCubit>().loadAllAccounts();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextInputField(
                    controller: _searchController,
                    hint: 'ابحث بالاسم أو الرمز أو البيان...',
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, size: 16),
                      const SizedBox(width: 6),
                      Text('الكل (${accounts.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.point_of_sale,
                        size: 16,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الصناديق (${accounts.where((a) => _matchesCategory(a, 1)).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'البنوك (${accounts.where((a) => _matchesCategory(a, 2)).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.indigo),
                      const SizedBox(width: 6),
                      Text(
                        'العملاء (${accounts.where((a) => _matchesCategory(a, 3)).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الموردين (${accounts.where((a) => _matchesCategory(a, 4)).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'أخرى (${accounts.where((a) => _matchesCategory(a, 5)).length})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(accounts, 0),
                  _buildList(accounts, 1),
                  _buildList(accounts, 2),
                  _buildList(accounts, 3),
                  _buildList(accounts, 4),
                  _buildList(accounts, 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AccountEntity> accounts, int categoryIndex) {
    final query = _query.trim().toLowerCase();
    final filtered = accounts.where((a) {
      final matchCat = _matchesCategory(a, categoryIndex);
      if (!matchCat) return false;
      if (query.isEmpty) return true;
      return a.name.toLowerCase().contains(query) ||
          a.code.toLowerCase().contains(query) ||
          (a.statement?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                query.isNotEmpty
                    ? 'لا توجد حسابات مطابقة للبحث "$_query"'
                    : 'لا توجد حسابات مضافة في هذا القسم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, i) {
        final a = filtered[i];
        final isBank = _matchesCategory(a, 2);
        final isCash = _matchesCategory(a, 1);
        final isCustomer = _matchesCategory(a, 3);
        final isSupplier = _matchesCategory(a, 4);

        Color avatarColor;
        IconData avatarIcon;

        if (isBank) {
          avatarColor = Colors.blue;
          avatarIcon = Icons.account_balance;
        } else if (isCash) {
          avatarColor = Colors.teal;
          avatarIcon = Icons.point_of_sale;
        } else if (isCustomer) {
          avatarColor = Colors.indigo;
          avatarIcon = Icons.person;
        } else if (isSupplier) {
          avatarColor = Colors.deepPurple;
          avatarIcon = Icons.local_shipping;
        } else {
          avatarColor = Colors.amber.shade800;
          avatarIcon = Icons.receipt_long;
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: avatarColor.withOpacity(0.12),
            foregroundColor: avatarColor,
            child: Icon(avatarIcon, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (a.balance != 0.0)
                Text(
                  a.balance.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: a.balance > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  a.code,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (a.statement != null && a.statement!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.statement!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            widget.onSelected(a);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
