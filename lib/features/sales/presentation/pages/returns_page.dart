import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_card_widget.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_header_widget.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SalesCubit>().loadReturnInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: CustomAppBar(title: 'مرتجعات المبيعات'),
      body: Column(
        children: [
          ReturnHeaderWidget(
            searchController: _searchController,
            onRefresh: () {
              context.read<SalesCubit>().loadReturnInvoices();
            },
            onChanged: (value) {
              // Implement search logic
            },
          ),
          Expanded(
            child: BlocConsumer<SalesCubit, SalesState>(
              listener: (context, state) {
                if (state is SalesError) {
                  AppToast.showError(context, state.message);
                } else if (state is ReturnInvoiceCreated) {
                  AppToast.showSuccess(
                    context,
                    'تم إنشاء فاتورة المرتجع بنجاح',
                  );
                  context.read<SalesCubit>().loadReturnInvoices();
                }
              },
              builder: (context, state) {
                if (state is SalesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ReturnInvoicesLoaded) {
                  if (state.returns.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'لا توجد مرتجعات',
                      subtitle: 'ستظهر مرتجعات المبيعات هنا',
                      icon: Icons.assignment_return_outlined,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<SalesCubit>().loadReturnInvoices();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.returns.length,
                      itemBuilder: (context, index) {
                        return ReturnCardWidget(
                          returnInvoice: state.returns[index],
                          onTap: () {
                            // Navigate to return detail
                          },
                          onViewEntries: () {
                            // View accounting entries
                          },
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('ابدأ بتحميل المرتجعات'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to select invoice page first
          context.pushNamed('select-invoice-for-return');
        },
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.assignment_return),
        label: const Text('مرتجع جديد'),
      ),
    );
  }
}

