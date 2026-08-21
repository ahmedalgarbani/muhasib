import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/templates/sales_accounting_template.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/pages/return_detail_page.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_card_widget.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_detail_components.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_header_widget.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  Future<Map<String, dynamic>> _loadReturnEntries(
    InvoiceEntity returnInvoice,
  ) async {
    final template = SalesAccountingTemplate();
    final productRepo = getIt<ProductRepository>();

    final productMap = <int, ProductEntity>{};
    final productResult = await productRepo.getProducts();
    productResult.fold((_) => null, (products) {
      for (final p in products) {
        if (p.id != null) productMap[p.id!] = p;
      }
    });

    final invoiceLines = returnInvoice.lines.map((line) {
      final cid = line.categoryId ?? 0;
      final product = productMap[cid];
      final name = product?.name ?? 'منتج #$cid';
      final cost = product?.costAmount ?? 0.0;
      final unitPrice = line.amount;
      return InvoiceLineEntry.fromInvoiceLine(
        categoryId: cid,
        productName: name,
        quantity: line.quantity,
        unitPrice: unitPrice,
        costPerUnit: cost,
      );
    }).toList();

    return template.generateSalesReturnEntries(
      customerId: returnInvoice.customerId,
      customerName: 'عميل #${returnInvoice.customerId}',
      returnNumber: returnInvoice.number,
      originalInvoiceNumber: returnInvoice.parentInvoiceNumber ?? 'N/A',
      returnDate: returnInvoice.date,
      totalAmount: returnInvoice.finalAmt ?? returnInvoice.amount,
      taxAmount: returnInvoice.taxAmt ?? 0,
      netAmount: returnInvoice.amount,
      lines: invoiceLines,
    );
  }

  void _showAccountingEntries(
    BuildContext context,
    InvoiceEntity returnInvoice,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          padding: AppConstant.defaultPadding,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ReturnDetailAccountingCard(
                  entriesFuture: _loadReturnEntries(returnInvoice),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'مرتجعات المبيعات'),
      body: Column(
        children: [
          ReturnHeaderWidget(
            searchController: _searchController,
            onRefresh: () {
              context.read<SalesCubit>().loadReturnInvoices();
            },
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
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
                  final filteredReturns = state.returns.where((ret) {
                    if (_searchQuery.trim().isEmpty) return true;
                    final q = _searchQuery.trim().toLowerCase();
                    final numberMatches = ret.number.toLowerCase().contains(q);
                    final parentMatches = (ret.parentInvoiceNumber ?? '')
                        .toLowerCase()
                        .contains(q);
                    final customerMatches = ret.customerId.toString().contains(
                      q,
                    );
                    return numberMatches || parentMatches || customerMatches;
                  }).toList();

                  if (filteredReturns.isEmpty) {
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
                      padding: AppConstant.defaultPadding,
                      itemCount: filteredReturns.length,
                      itemBuilder: (context, index) {
                        final returnInvoice = filteredReturns[index];
                        return ReturnCardWidget(
                          returnInvoice: returnInvoice,
                          onTap: () {
                            context.pushNamed(
                              AppRoutes.salesReturnDetail,
                              extra: returnInvoice,
                            );
                          },
                          onViewEntries: () {
                            _showAccountingEntries(context, returnInvoice);
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
          // Navigate to select invoice page
          context.pushNamed(AppRoutes.selectInvoiceForReturn);
        },
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.assignment_return),
        label: const Text('مرتجع جديد'),
      ),
    );
  }
}
