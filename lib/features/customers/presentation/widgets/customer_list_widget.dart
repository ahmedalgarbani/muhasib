import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';

class CustomerListWidget extends StatelessWidget {
  final String searchQuery;

  const CustomerListWidget({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        if (state is CustomersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CustomersError) {
          return PartyProfileErrorState(
            message: state.message,
            onRetry: () => context.read<CustomersCubit>().loadCustomers(),
          );
        }
        if (state is! CustomersLoaded) return const SizedBox.shrink();

        final allCustomers = state.customers;
        final query = searchQuery.toLowerCase().trim();
        final customers = allCustomers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              (customer.phone?.contains(query) ?? false);
        }).toList();

        if (customers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.person_off,
            title: query.isEmpty ? 'لا يوجد عملاء مضافين بعد' : 'لا توجد نتائج للبحث',
          );
        }

        return Column(
          children: [
            if (query.isEmpty) _buildCustomerSummaryHeader(context, allCustomers),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return PartyProfileCard(
                    party: customer,
                    isSupplier: false,
                    onTap: () => showPartyDetailsSheet(context, customer, false),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerSummaryHeader(BuildContext context, List<Customer> customers) {
    final totalCustomers = customers.length;
    double totalDebit = 0; // الديون عليهم
    double totalCredit = 0; // أرصدة دائنة لهم
    int overLimitCount = 0;

    for (final c in customers) {
      if (c.balance > 0.001) {
        totalDebit += c.balance;
        if (c.creditLimit > 0 && c.balance > c.creditLimit) {
          overLimitCount++;
        }
      } else if (c.balance < -0.001) {
        totalCredit += c.balance.abs();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'الديون المستحقة (عليهم)',
              value: '${totalDebit.toStringAsFixed(0)} ر.س',
              subtitle: '$totalCustomers عميل',
              color: Colors.red.shade700,
              backgroundColor: Colors.red.shade50,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'أرصدة متبقية (لهم)',
              value: '${totalCredit.toStringAsFixed(0)} ر.س',
              subtitle: overLimitCount > 0 ? '$overLimitCount متجاوز للحد' : 'الحسابات نشطة',
              color: Colors.green.shade700,
              backgroundColor: Colors.green.shade50,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

