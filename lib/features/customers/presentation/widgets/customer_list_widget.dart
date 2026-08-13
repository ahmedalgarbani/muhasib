import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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

        final query = searchQuery.toLowerCase();
        final customers = state.customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              (customer.phone?.contains(searchQuery) ?? false);
        }).toList();

        if (customers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.person_off,
            title: query.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج للبحث',
          );
        }

        return ListView.builder(
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
        );
      },
    );
  }
}
