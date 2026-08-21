import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_action_buttons.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_header.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_info_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_notes_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_products_list.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_supplier_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_totals_card.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';

class PurchaseDetailPage extends StatefulWidget {
  final InvoiceEntity invoice;

  const PurchaseDetailPage({super.key, required this.invoice});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PurchasesCubit _purchasesCubit;

  @override
  void initState() {
    super.initState();
    _purchasesCubit = getIt<PurchasesCubit>();
  }

  @override
  void dispose() {
    _purchasesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _purchasesCubit),
        BlocProvider(create: (_) => getIt<CustomersCubit>()..loadSuppliers()),
        BlocProvider(create: (_) => getIt<ProductsCubit>()..loadProducts()),
      ],
      child: BlocConsumer<PurchasesCubit, PurchasesState>(
        bloc: _purchasesCubit,
        listener: (context, state) {
          if (state is PurchaseInvoiceDeleted) {
            AppToast.showSuccess(
              context,
              'تم حذف فاتورة المشتريات وعكس قيودها بنجاح',
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            } else if (context.canPop()) {
              context.pop(true);
            }
          } else if (state is PurchasesError) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is PurchasesLoading;

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.neutral100,
            appBar: const CustomAppBar(),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: AppConstant.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PurchaseDetailHeader(invoice: widget.invoice),
                      const SizedBox(height: 10),
                      PurchaseDetailInfoCard(invoice: widget.invoice),
                      const SizedBox(height: 16),
                      PurchaseDetailSupplierCard(invoice: widget.invoice),
                      const SizedBox(height: 16),
                      PurchaseDetailProductsList(lines: widget.invoice.lines),
                      const SizedBox(height: 16),
                      PurchaseDetailTotalsCard(invoice: widget.invoice),
                      const SizedBox(height: 16),
                      if (widget.invoice.statement != null &&
                          widget.invoice.statement!.isNotEmpty) ...[
                        PurchaseDetailNotesCard(
                          notes: widget.invoice.statement!,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),
                      PurchaseDetailActionButtons(
                        onEdit: () async {
                          final res = await context.push(
                            AppRoutes.purchasesAddInvoice,
                            extra: widget.invoice,
                          );
                          if (res == true && context.mounted) {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop(true);
                            } else if (context.canPop()) {
                              context.pop(true);
                            }
                          }
                        },
                        onPrint: () {
                          AppToast.showInfo(
                            context,
                            'سيتم إضافة ميزة الطباعة قريباً',
                          );
                        },
                        onDelete: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: 'تأكيد الحذف',
        content: const Text(
          'هل أنت متأكد من حذف هذه الفاتورة؟ سيتم إلغاء أثرها وعكس قيدها المحاسبي ومخزونها تلقائياً.',
        ),
        actions: [
          HasibButton(
            label: 'إلغاء',
            onPressed: () => Navigator.of(dialogContext).pop(),
            variant: HasibButtonVariant.secondary,
          ),
          const SizedBox(width: 12),
          HasibButton(
            label: 'حذف الفاتورة',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (widget.invoice.id != null) {
                _purchasesCubit.deletePurchaseInvoice(widget.invoice.id!);
              }
            },
            variant: HasibButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}
