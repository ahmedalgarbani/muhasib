import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class PurchasesListPage extends StatefulWidget {
  const PurchasesListPage({super.key});

  @override
  State<PurchasesListPage> createState() => _PurchasesListPageState();
}

class _PurchasesListPageState extends State<PurchasesListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Loading is triggered in BlocProvider.create below
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PurchasesCubit>()..loadPurchaseInvoices(),
      child: Builder(
        builder: (innerContext) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.gray50,
          appBar: CustomAppBar(),
          body: Column(
            children: [
              _buildHeader(innerContext),
              Expanded(
                child: BlocBuilder<PurchasesCubit, PurchasesState>(
                  builder: (context, state) {
                    if (state is PurchasesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is PurchasesError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is PurchaseInvoicesLoaded) {
                      if (state.invoices.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildInvoicesList(innerContext, state.invoices);
                    }
                    return const Center(
                      child: Text('ابدأ بتحميل فواتير المشتريات'),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              innerContext.push(AppRoutes.purchasesAddInvoice);
            },
            backgroundColor: AppColors.success,
            icon: const Icon(Icons.add),
            label: const Text('فاتورة جديدة'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext innerContext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'فواتير المشتريات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextInputField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث في فواتير المشتريات...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.success),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      innerContext.read<PurchasesCubit>().searchPurchases(
                        value,
                      );
                    } else {
                      innerContext
                          .read<PurchasesCubit>()
                          .loadPurchaseInvoices();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  innerContext.read<PurchasesCubit>().loadPurchaseInvoices();
                },
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(
    BuildContext innerContext,
    List<InvoiceEntity> invoices,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        innerContext.read<PurchasesCubit>().loadPurchaseInvoices();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(invoices[index]);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceEntity invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement purchase invoice detail navigation
          // context.pushNamed(AppRoutes.purchaseDetail, extra: invoice);
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 20,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              invoice.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(invoice.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg20),
                    ),
                    child: const Text(
                      'مشتريات',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'المورد #${invoice.customerId}', // In purchases, customer field holds supplier
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (invoice.statement != null) ...[
                Text(
                  invoice.statement!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المبلغ الإجمالي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(invoice.finalAmt ?? invoice.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  _buildPaymentStatusChip(invoice.paymentStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(int status) {
    String text;
    Color color;

    switch (status) {
      case 1:
        text = 'مدفوعة';
        color = Colors.green;
        break;
      case 2:
        text = 'مدفوعة جزئياً';
        color = Colors.orange;
        break;
      default:
        text = 'غير مدفوعة';
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير مشتريات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة فاتورة مشتريات جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ريال';
  }
}
