import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/widgets/customer_list_widget.dart';
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
            Expanded(
              child: CustomerListWidget(searchQuery: _searchQuery),
            ),
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
