import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';

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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            PartyProfileSearchField(
              controller: _searchController,
              query: _searchQuery,
              hintText: 'البحث عن عميل...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            Expanded(child: _buildCustomerList()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddCustomerDialog(context),
          icon: const Icon(Icons.person_add),
          label: const Text('إضافة عميل'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
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

        final query = _searchQuery.toLowerCase();
        final customers = state.customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              (customer.phone?.contains(_searchQuery) ?? false);
        }).toList();

        if (customers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.person_off,
            title: query.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج للبحث',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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

  Future<void> _openAddCustomerDialog(BuildContext context) async {
    final cubit = context.read<CustomersCubit>();
    final newCustomer = await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const AddCustomerDialog(partyType: 1),
      ),
    );

    if (newCustomer != null && mounted) {
      cubit.loadCustomers();
    }
  }
}
