import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';
import 'package:muhasib/features/customers/presentation/widgets/supplier_list_widget.dart';
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
            Expanded(
              child: SupplierListWidget(searchQuery: _searchQuery),
            ),
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
