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
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBarAccountDetail(onMenuPressed: null),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('تنازلياً')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDropdown('التاريخ')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDropdown('نوع العملية')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPeriodOption('سنوي'),
                            _buildPeriodOption('الكل'),
                            _buildPeriodOption('شهري'),
                            _buildPeriodOption('يومي'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField('الى تاريخ:', endDate),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDateField('من تاريخ:', startDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
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
                    return _buildTransactionItem(
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

  Widget _buildDropdown(String value) {
    return DropdownButtonFormField<String>(
      itemHeight: 48.0,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
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

  Widget _buildPeriodOption(String label) {
    bool isSelected = selectedPeriod == label;
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: selectedPeriod,
          onChanged: (value) {
            setState(() {
              selectedPeriod = value!;
            });
          },
          activeColor: Colors.blue,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        color: Colors.grey[50],
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

  Widget _buildTransactionItem({
    required String title,
    required String debit,
    required String credit,
    required String balance,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    icon: const Icon(
                      Icons.share,
                      color: Colors.black,
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
      color: Colors.white,
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
      backgroundColor: Colors.white,
      title: const Text(
        'حسيب',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_outlined,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(
            Icons.filter_alt_off_rounded,
            color: Colors.black,
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
