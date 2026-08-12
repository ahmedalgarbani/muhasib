import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/detail_row.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';

class CustomersProfilePage extends StatelessWidget {
  const CustomersProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomersCubit>()..loadCustomers(),
      child: const _CustomersProfileContent(),
    );
  }
}

class _CustomersProfileContent extends StatefulWidget {
  const _CustomersProfileContent();

  @override
  State<_CustomersProfileContent> createState() =>
      _CustomersProfileContentState();
}

class _CustomersProfileContentState extends State<_CustomersProfileContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'العملاء',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<CustomersCubit>().loadCustomers(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث عن عميل...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(77),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Customer list
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  if (state is CustomersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CustomersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(color: colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.read<CustomersCubit>().loadCustomers(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CustomersLoaded) {
                    final customers = state.customers
                        .where(
                          (c) =>
                              c.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (c.phone?.contains(_searchQuery) ?? false),
                        )
                        .toList();

                    if (customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا يوجد عملاء'
                                  : 'لا توجد نتائج للبحث',
                              style: TextStyle(
                                color: colorScheme.outline,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return _CustomerCard(customer: customer);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCustomerDialog(context),
          icon: const Icon(Icons.person_add),
          label: const Text('إضافة عميل'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final creditLimitController = TextEditingController(text: '0');
    final openingBalanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: 'إضافة عميل جديد',
        icon: Icons.person_add,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextInputField(
              label: 'اسم العميل',
              isRequired: true,
              textEditingController: nameController,
              prefixIcon: const Icon(Icons.person),
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'رقم الهاتف',
              textEditingController: phoneController,
              inputType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'العنوان',
              textEditingController: addressController,
              prefixIcon: const Icon(Icons.location_on),
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'حد الائتمان',
              textEditingController: creditLimitController,
              inputType: TextInputType.number,
              prefixIcon: const Icon(Icons.credit_card),
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'الرصيد الافتتاحي',
              textEditingController: openingBalanceController,
              inputType: TextInputType.number,
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إنشاء حساب تلقائياً للعميل في شجرة الحسابات',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          HasibButton(
            label: 'إلغاء',
            variant: HasibButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          const SizedBox(width: 12),
          HasibButton(
            label: 'إضافة',
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى إدخال اسم العميل'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final cubit = context.read<CustomersCubit>();
              final customer = await cubit.addCustomer(
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                type: 1,
                creditLimit: double.tryParse(creditLimitController.text) ?? 0,
                openingBalance:
                    double.tryParse(openingBalanceController.text) ?? 0,
              );

              if (customer != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إضافة العميل "${customer.name}" بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOverLimit =
        customer.creditLimit > 0 && customer.balance > customer.creditLimit;
    final hasDebt = customer.balance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showCustomerDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (customer.phone != null &&
                            customer.phone!.isNotEmpty)
                          Text(
                            customer.phone!,
                            style: TextStyle(
                              color: colorScheme.outline,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${customer.balance.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: hasDebt ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        hasDebt ? 'عليه' : 'متوازن',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasDebt ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (customer.creditLimit > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: (customer.balance / customer.creditLimit).clamp(
                      0.0,
                      1.0,
                    ),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      isOverLimit ? Colors.red : colorScheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حد الائتمان: ${customer.creditLimit.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline,
                      ),
                    ),
                    if (isOverLimit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Text(
                          'تجاوز الحد',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withAlpha(77),
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.phone != null)
                          Text(
                            customer.phone!,
                            style: TextStyle(color: colorScheme.outline),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: customer.balance > 0 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الرصيد الحالي',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '${customer.balance.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (customer.creditLimit > 0)
                DetailRow(
                  icon: Icons.credit_card,
                  label: 'حد الائتمان',
                  value: '${customer.creditLimit.toStringAsFixed(0)} ر.س',
                ),

              if (customer.address != null && customer.address!.isNotEmpty)
                DetailRow(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: customer.address!,
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.article),
                      label: const Text('كشف حساب'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.receipt),
                      label: const Text('فاتورة جديدة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

