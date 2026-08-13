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
                selectedAccountName ??
                    'ط§ط®طھط± ط§ظ„ط­ط³ط§ط¨ ظ…ظ† ط§ظ„ظ‚ط§ط¦ظ…ط©...',
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
                    'ط§ط®طھظٹط§ط± ط§ظ„ط­ط³ط§ط¨',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextInputField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ط§ط¨ط­ط« ط¹ظ† ط­ط³ط§ط¨...',
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
                Tab(text: 'ط§ظ„ظƒظ„'),
                Tab(text: 'ط§ظ„طµظ†ط§ط¯ظٹظ‚'),
                Tab(text: 'ط§ظ„ط¨ظ†ظˆظƒ'),
                Tab(text: 'ط§ظ„ط¹ظ…ظ„ط§ط،'),
                Tab(text: 'ط§ظ„ظ…ظˆط±ط¯ظٹظ†'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(accounts, null),
                  _buildList(accounts, 'طµظ†ط¯ظˆظ‚'),
                  _buildList(accounts, 'ط¨ظ†ظƒ'),
                  _buildList(accounts, 'ط¹ظ…ظٹظ„'),
                  _buildList(accounts, 'ظ…ظˆط±ط¯'),
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
