import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchase_form_page.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_order_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_orders_header.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PurchasesCubit>()..loadPurchaseOrders(),
      child: Builder(
        builder: (innerContext) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.gray50,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              PurchaseOrdersHeader(
                searchController: _searchController,
                onRefresh: () =>
                    innerContext.read<PurchasesCubit>().loadPurchaseOrders(),
              ),
              Expanded(
                child: BlocBuilder<PurchasesCubit, PurchasesState>(
                  builder: (context, state) {
                    if (state is PurchasesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is PurchasesError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            HasibButton(
                              label: 'إعادة المحاولة',
                              onPressed: () => innerContext
                                  .read<PurchasesCubit>()
                                  .loadPurchaseOrders(),
                              leading: const Icon(Icons.refresh, size: 18),
                              variant: HasibButtonVariant.success,
                              fontSize: 13,
                            ),
                          ],
                        ),
                      );
                    } else if (state is PurchaseOrdersLoaded) {
                      if (state.orders.isEmpty) {
                        return EmptyStateWidget(
                          title: 'لا توجد طلبات شراء',
                          subtitle: 'ابدأ بإنشاء طلب شراء جديد',
                          icon: Icons.shopping_basket_outlined,
                          iconSize: 64,
                          iconColor: AppColors.info.withOpacity(0.3),
                          actionText: 'إنشاء طلب شراء',
                          onActionPressed: () {
                            AppToast.showWarning(
                              context,
                              'سيتم إضافة صفحة إنشاء طلب شراء قريباً',
                            );
                          },
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          innerContext.read<PurchasesCubit>().loadPurchaseOrders();
                        },
                        child: ListView.builder(
                          padding: AppConstant.defaultPadding,
                          itemCount: state.orders.length,
                          itemBuilder: (context, index) {
                            final order = state.orders[index];
                            return PurchaseOrderCard(
                              order: order,
                              onConvert: () => _showConvertDialog(innerContext, order),
                            );
                          },
                        ),
                      );
                    }
                    return const Center(
                      child: Text('ابدأ بتحميل طلبات الشراء'),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                innerContext,
                MaterialPageRoute(
                  builder: (_) => const PurchaseFormPage(invoiceType: 3),
                ),
              );
            },
            backgroundColor: AppColors.info,
            icon: const Icon(Icons.add_shopping_cart, size: 20),
            label: const Text('طلب شراء جديد', style: TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext innerContext, InvoiceEntity order) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Row(
          children: [
            Icon(Icons.transform, color: AppColors.success),
            SizedBox(width: 8),
            Text('تحويل طلب الشراء'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل تريد تحويل طلب الشراء هذا إلى فاتورة مشتريات؟',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إنشاء فاتورة مشتريات جديدة بنفس البيانات',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          HasibButton(
            label: 'تحويل',
            onPressed: () {
              Navigator.of(context).pop();
              final newInvoiceNumber =
                  'INV-${DateTime.now().millisecondsSinceEpoch}';
              final newInvoice = InvoiceEntity(
                number: newInvoiceNumber,
                date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                customerId: order.customerId,
                stockId: order.stockId,
                amount: order.amount,
                totalAmount: order.totalAmount,
                finalAmt: order.finalAmt,
                taxAmt: order.taxAmt,
                taxRatio: order.taxRatio,
                discountAmt: order.discountAmt,
                discountRatio: order.discountRatio,
                otherFeeAmt: order.otherFeeAmt,
                otherFeeNetRatio: order.otherFeeNetRatio,
                otherFeeAccountId: order.otherFeeAccountId,
                totalAmountAfterDiscount: order.totalAmountAfterDiscount,
                statement: order.statement,
                lines: order.lines,
                invoiceType: 2, // Purchase Invoice
                invoiceTransType: 1,
                paymentStatus: 0,
              );
              innerContext.read<PurchasesCubit>().convertOrderToInvoice(
                    order.id!,
                    newInvoice,
                  );
            },
            leading: const Icon(Icons.check, size: 18),
            variant: HasibButtonVariant.success,
          ),
        ],
      ),
    );
  }
}
