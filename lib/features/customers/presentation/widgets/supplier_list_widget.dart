import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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

        final query = searchQuery.toLowerCase();
        final suppliers = state.suppliers.where((supplier) {
          return supplier.name.toLowerCase().contains(query) ||
              (supplier.phone?.contains(searchQuery) ?? false);
        }).toList();

        if (suppliers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: query.isEmpty ? 'لا يوجد موردين' : 'لا توجد نتائج للبحث',
          );
        }

        return ListView.builder(
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
        );
      },
    );
  }
}
