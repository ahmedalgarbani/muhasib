import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';

class SupplierListWidget extends StatelessWidget {
  final String searchQuery;

  const SupplierListWidget({
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
            onRetry: () => context.read<CustomersCubit>().loadSuppliers(),
          );
        }
        if (state is! SuppliersLoaded) return const SizedBox.shrink();

        final allSuppliers = state.suppliers;
        final query = searchQuery.toLowerCase().trim();
        final suppliers = allSuppliers.where((supplier) {
          return supplier.name.toLowerCase().contains(query) ||
              (supplier.phone?.contains(query) ?? false);
        }).toList();

        if (suppliers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: query.isEmpty ? 'لا يوجد موردين مضافين بعد' : 'لا توجد نتائج للبحث',
          );
        }

        return Column(
          children: [
            if (query.isEmpty) _buildSupplierSummaryHeader(context, allSuppliers),
            Expanded(
              child: ListView.builder(
                padding: AppConstant.defaultPadding,
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return PartyProfileCard(
                    party: supplier,
                    isSupplier: true,
                    onTap: () => showPartyDetailsSheet(context, supplier, true),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierSummaryHeader(BuildContext context, List<Customer> suppliers) {
    final totalSuppliers = suppliers.length;
    double totalDue = 0; // مستحقات لهم
    double totalAdvance = 0; // دفعات مقدمة عليهم

    for (final s in suppliers) {
      if (s.balance > 0.001) {
        totalDue += s.balance;
      } else if (s.balance < -0.001) {
        totalAdvance += s.balance.abs();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'مستحقات الموردين (لهم)',
              value: '${totalDue.toStringAsFixed(0)} ر.س',
              subtitle: '$totalSuppliers مورد',
              color: Colors.orange.shade900,
              backgroundColor: Colors.orange.shade50,
              icon: Icons.business,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'مدفوعات مقدمة (عليهم)',
              value: '${totalAdvance.toStringAsFixed(0)} ر.س',
              subtitle: 'أرصدة للمنشأة',
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

