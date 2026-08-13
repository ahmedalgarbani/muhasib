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

  void _pickAccount(BuildContext context) {
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
