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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
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
                    controller: _searchController,
                    hint: 'ابحث عن حساب...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm14),
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
                  VoucherAccountListWidget(
                    allAccounts: accounts,
                    searchQuery: _searchQuery,
                    filter: null,
                    onSelected: widget.onSelected,
                  ),
                  VoucherAccountListWidget(
                    allAccounts: accounts,
                    searchQuery: _searchQuery,
                    filter: 'صندوق',
                    onSelected: widget.onSelected,
                  ),
                  VoucherAccountListWidget(
                    allAccounts: accounts,
                    searchQuery: _searchQuery,
                    filter: 'بنك',
                    onSelected: widget.onSelected,
                  ),
                  VoucherAccountListWidget(
                    allAccounts: accounts,
                    searchQuery: _searchQuery,
                    filter: 'عميل',
                    onSelected: widget.onSelected,
                  ),
                  VoucherAccountListWidget(
                    allAccounts: accounts,
                    searchQuery: _searchQuery,
                    filter: 'مورد',
                    onSelected: widget.onSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoucherAccountListWidget extends StatelessWidget {
  final List<AccountEntity> allAccounts;
  final String searchQuery;
  final String? filter;
  final Function(AccountEntity) onSelected;

  const VoucherAccountListWidget({
    super.key,
    required this.allAccounts,
    required this.searchQuery,
    this.filter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = allAccounts.where((a) {
      final matchSearch =
          a.name.contains(searchQuery) || a.code.contains(searchQuery);
      if (filter == null) return matchSearch;
      final matchFilter = a.name.contains(filter!);
      return matchSearch && matchFilter;
    }).toList();

    return ListView.builder(
      padding: AppConstant.defaultPadding,
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
