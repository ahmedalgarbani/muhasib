import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AccountTransactionPage extends StatefulWidget {
  const AccountTransactionPage({super.key});

  @override
  State<AccountTransactionPage> createState() => _AccountTransactionPageState();
}

class _AccountTransactionPageState extends State<AccountTransactionPage> {
  String selectedPeriod = 'شهري';
  DateTime startDate = DateTime(2025, 10, 1);
  DateTime endDate = DateTime(2025, 10, 31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBarAccountDetail(onMenuPressed: null),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              child: AccountDropdownFieldWidget(
                                value: 'تنازلياً',
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: AccountDropdownFieldWidget(
                                value: 'التاريخ',
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: AccountDropdownFieldWidget(
                                value: 'نوع العملية',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            AccountPeriodOptionRadioWidget(
                              label: 'سنوي',
                              selectedPeriod: selectedPeriod,
                              onChanged: (val) =>
                                  setState(() => selectedPeriod = val),
                            ),
                            AccountPeriodOptionRadioWidget(
                              label: 'الكل',
                              selectedPeriod: selectedPeriod,
                              onChanged: (val) =>
                                  setState(() => selectedPeriod = val),
                            ),
                            AccountPeriodOptionRadioWidget(
                              label: 'شهري',
                              selectedPeriod: selectedPeriod,
                              onChanged: (val) =>
                                  setState(() => selectedPeriod = val),
                            ),
                            AccountPeriodOptionRadioWidget(
                              label: 'يومي',
                              selectedPeriod: selectedPeriod,
                              onChanged: (val) =>
                                  setState(() => selectedPeriod = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AccountDateFieldWidget(
                                label: 'الى تاريخ:',
                                date: endDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AccountDateFieldWidget(
                                label: 'من تاريخ:',
                                date: startDate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text(
                            'الرصيد',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'دائن',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'مدين',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'التاريخ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(10, (index) {
                    return AccountOldTransactionItemWidget(
                      title: 'قيد يومي بالرقم: ${index + 1}',
                      debit: '600',
                      credit: '0',
                      balance: '600-',
                      date: '16 - 10 - 2025',
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const BottomCollectionDataCalculator(),
        ],
      ),
    );
  }
}

class AccountDropdownFieldWidget extends StatelessWidget {
  final String value;

  const AccountDropdownFieldWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      itemHeight: 48.0,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: const [],
      onChanged: (a) {},
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}

class AccountPeriodOptionRadioWidget extends StatelessWidget {
  final String label;
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const AccountPeriodOptionRadioWidget({
    super.key,
    required this.label,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: selectedPeriod,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          activeColor: Colors.blue,
        ),
        Text(label),
      ],
    );
  }
}

class AccountDateFieldWidget extends StatelessWidget {
  final String label;
  final DateTime date;

  const AccountDateFieldWidget({
    super.key,
    required this.label,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          Text(
            '$label ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class AccountOldTransactionItemWidget extends StatelessWidget {
  final String title;
  final String debit;
  final String credit;
  final String balance;
  final String date;

  const AccountOldTransactionItemWidget({
    super.key,
    required this.title,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  balance,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                Text(credit, style: const TextStyle(fontSize: 16)),
                Text(debit, style: const TextStyle(fontSize: 16)),
                Text(
                  date,
                  style: const TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomCollectionDataCalculator extends StatelessWidget {
  const BottomCollectionDataCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('600', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('الاجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('600 مدين', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomAppBarAccountDetail extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarAccountDetail({super.key, required this.onMenuPressed});
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Text(
        'محاسب',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_outlined,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.filter_alt_off_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
