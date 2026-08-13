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
        borderRadius: BorderRadius.vertical(
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
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
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
                TextInputField(
                  label: 'قيمة الرصيد',
                  textEditingController: _amountController,
                  inputType: TextInputType.number,
                  prefixIcon: const Icon(Icons.calculate_outlined),
                  hint: '0.00',
                ),
                const SizedBox(height: 32),
                HasibButton(
                  label: 'إضافة للجدول',
                  onPressed: _submit,
                  variant: HasibButtonVariant.primary,
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
          borderRadius: BorderRadius.circular(AppRadius.md),
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextInputField(
                hint: 'ابحث عن حساب...',
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
