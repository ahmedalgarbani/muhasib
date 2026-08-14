part of 'voucher_form_page.dart';

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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).dividerColor),
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
                      ? Theme.of(context).colorScheme.onSurface
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

enum AccountCategoryFilter {
  all,
  cashboxes,
  banks,
  customers,
  suppliers,
  other;

  bool matches(AccountEntity a) {
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

    switch (this) {
      case AccountCategoryFilter.all:
        return true;
      case AccountCategoryFilter.cashboxes:
        return isCash;
      case AccountCategoryFilter.banks:
        return isBank;
      case AccountCategoryFilter.customers:
        return isCustomer;
      case AccountCategoryFilter.suppliers:
        return isSupplier;
      case AccountCategoryFilter.other:
        return !isCash && !isBank && !isCustomer && !isSupplier;
    }
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
    _tabController = TabController(length: 6, vsync: this);
    context.read<AccountsCubit>().loadAllAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final accounts = context.watch<AccountsCubit>().allAccounts ?? [];
        final isLoading = state is AccountsLoading && accounts.isEmpty;

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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
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
                            'الصناديق (${accounts.where((a) => AccountCategoryFilter.cashboxes.matches(a)).length})',
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
                            'البنوك (${accounts.where((a) => AccountCategoryFilter.banks.matches(a)).length})',
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'العملاء (${accounts.where((a) => AccountCategoryFilter.customers.matches(a)).length})',
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
                            'الموردين (${accounts.where((a) => AccountCategoryFilter.suppliers.matches(a)).length})',
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'أخرى (${accounts.where((a) => AccountCategoryFilter.other.matches(a)).length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.all,
                              onSelected: widget.onSelected,
                            ),
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.cashboxes,
                              onSelected: widget.onSelected,
                            ),
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.banks,
                              onSelected: widget.onSelected,
                            ),
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.customers,
                              onSelected: widget.onSelected,
                            ),
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.suppliers,
                              onSelected: widget.onSelected,
                            ),
                            VoucherAccountListWidget(
                              allAccounts: accounts,
                              searchQuery: _searchQuery,
                              categoryFilter: AccountCategoryFilter.other,
                              onSelected: widget.onSelected,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VoucherAccountListWidget extends StatelessWidget {
  final List<AccountEntity> allAccounts;
  final String searchQuery;
  final AccountCategoryFilter categoryFilter;
  final Function(AccountEntity) onSelected;

  const VoucherAccountListWidget({
    super.key,
    required this.allAccounts,
    required this.searchQuery,
    required this.categoryFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = allAccounts.where((a) {
      final matchCategory = categoryFilter.matches(a);
      if (!matchCategory) return false;

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
                    ? 'لا توجد حسابات مطابقة للبحث "$searchQuery"'
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
        final isBank = AccountCategoryFilter.banks.matches(a);
        final isCash = AccountCategoryFilter.cashboxes.matches(a);
        final isCustomer = AccountCategoryFilter.customers.matches(a);
        final isSupplier = AccountCategoryFilter.suppliers.matches(a);

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
            onSelected(a);
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
