import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class CustomerBottomSheet extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onSelect;

  const CustomerBottomSheet({
    Key? key,
    required this.customers,
    required this.onSelect,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required List<Customer> customers,
    required Function(Customer) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CustomerBottomSheet(customers: customers, onSelect: onSelect),
    );
  }

  @override
  State<CustomerBottomSheet> createState() => _CustomerBottomSheetState();
}

class _CustomerBottomSheetState extends State<CustomerBottomSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = widget.customers
        .where((c) => c.name.contains(_searchQuery))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '�?�?�?�?�?�? �?�?�?�?�?�?',
                      style: AppTextStyles.title,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: '�?�?�?� �?�? �?�?�?�?...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(child: Text('�?�? �?�?�?�? �?�?�?�?�?'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return InkWell(
                        onTap: () {
                          widget.onSelect(customer);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.grey200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: AppTextStyles.body),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '�?�?�?���?�?: ${NumberFormatter.formatCurrency(customer.balance)}',
                                    style: AppTextStyles.small.copyWith(
                                      color: customer.hasDebt
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    '�?�?�?�?: ${NumberFormatter.formatCurrency(customer.creditLimit)}',
                                    style: AppTextStyles.small,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
