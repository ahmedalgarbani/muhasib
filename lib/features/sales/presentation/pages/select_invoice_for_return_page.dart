import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/select_return_invoice_card_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class SelectInvoiceForReturnPage extends StatefulWidget {
  const SelectInvoiceForReturnPage({super.key});

  @override
  State<SelectInvoiceForReturnPage> createState() =>
      _SelectInvoiceForReturnPageState();
}

class _SelectInvoiceForReturnPageState
    extends State<SelectInvoiceForReturnPage> {
  final TextEditingController _searchController = TextEditingController();
  List<InvoiceEntity> _filteredInvoices = [];
  List<InvoiceEntity> _allInvoices = [];

  @override
  void initState() {
    super.initState();
    // Load sales invoices only (not returns or quotations)
    context.read<SalesCubit>().loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = _allInvoices;
      } else {
        _filteredInvoices = _allInvoices.where((invoice) {
          return invoice.number.toLowerCase().contains(query.toLowerCase()) ||
              invoice.customerId.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: CustomAppBar(title: 'اختر الفاتورة لإنشاء مرتجع'),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: AppConstant.defaultPadding,
            color: Colors.white,
            child: TextInputField(
              controller: _searchController,
              hint: 'ابحث برقم الفاتورة أو اسم العميل...',
              onChanged: _filterInvoices,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Invoices List
          Expanded(
            child: BlocBuilder<SalesCubit, SalesState>(
              builder: (context, state) {
                if (state is SalesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SalesLoaded) {
                  // Filter only sales invoices (type 0 or 1)
                  _allInvoices = state.invoices.where((invoice) {
                    // Filter only sales invoices (type 1) and quick invoices (type 6)
                    return invoice.invoiceType == 1 || invoice.invoiceType == 6;
                  }).toList();

                  if (_filteredInvoices.isEmpty &&
                      _searchController.text.isEmpty) {
                    _filteredInvoices = _allInvoices;
                  }

                  if (_filteredInvoices.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'لا توجد فواتير مبيعات',
                      subtitle: 'قم بإنشاء فاتورة مبيعات أولاً',
                      icon: Icons.receipt_long_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: AppConstant.defaultPadding,
                    itemCount: _filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _filteredInvoices[index];
                      return SelectReturnInvoiceCardWidget(
                        invoice: invoice,
                        onTap: () {
                          context.pushNamed(
                            'sales-returns-form',
                            queryParameters: {'invoiceId': invoice.id.toString()},
                          );
                        },
                      );
                    },
                  );
                } else if (state is SalesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        HasibButton(
                          label: 'إعادة المحاولة',
                          onPressed: () {
                            context.read<SalesCubit>().loadInvoices();
                          },
                          variant: HasibButtonVariant.primary,
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text('ابدأ بتحميل الفواتير'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

