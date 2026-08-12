import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';

class SuppliersProfilePage extends StatelessWidget {
  const SuppliersProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomersCubit>()..loadSuppliers(),
      child: const _SuppliersProfileContent(),
    );
  }
}

class _SuppliersProfileContent extends StatefulWidget {
  const _SuppliersProfileContent();

  @override
  State<_SuppliersProfileContent> createState() =>
      _SuppliersProfileContentState();
}

class _SuppliersProfileContentState extends State<_SuppliersProfileContent> {
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
          title: 'الموردين',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<CustomersCubit>().loadSuppliers(),
            ),
          ],
        ),
        body: Column(
          children: [
            PartyProfileSearchField(
              controller: _searchController,
              query: _searchQuery,
              hintText: 'البحث عن مورد...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            Expanded(child: _buildSupplierList()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddSupplierDialog(context),
          icon: const Icon(Icons.add_business),
          label: const Text('إضافة مورد'),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
        ),
      ),
    );
  }

  Widget _buildSupplierList() {
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

        final query = _searchQuery.toLowerCase();
        final suppliers = state.suppliers.where((supplier) {
          return supplier.name.toLowerCase().contains(query) ||
              (supplier.phone?.contains(_searchQuery) ?? false);
        }).toList();

        if (suppliers.isEmpty) {
          return PartyProfileEmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: query.isEmpty ? 'لا يوجد موردين' : 'لا توجد نتائج للبحث',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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

  Future<void> _openAddSupplierDialog(BuildContext context) async {
    final cubit = context.read<CustomersCubit>();
    final newSupplier = await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const AddCustomerDialog(partyType: 2),
      ),
    );

    if (newSupplier != null && mounted) {
      cubit.loadSuppliers();
    }
  }
}
