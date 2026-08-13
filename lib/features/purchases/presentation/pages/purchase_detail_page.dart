import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_action_buttons.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_header.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_info_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_notes_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_products_list.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_supplier_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_detail_totals_card.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseDetailPage extends StatefulWidget {
  final InvoiceEntity invoice;

  const PurchaseDetailPage({super.key, required this.invoice});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PurchasesCubit>(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.neutral100,
        appBar: const CustomAppBar(),
        body: SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PurchaseDetailHeader(invoice: widget.invoice),
              const SizedBox(height: 20),
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
                PurchaseDetailNotesCard(notes: widget.invoice.statement!),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              PurchaseDetailActionButtons(
                onEdit: () {
                  context.push(
                    AppRoutes.purchasesAddInvoice,
                    extra: widget.invoice,
                  );
                },
                onPrint: () {
                  AppToast.showInfo(context, 'سيتم إضافة ميزة الطباعة قريباً');
                },
                onDelete: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'حذف',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PurchasesCubit>().deletePurchaseInvoice(
                    widget.invoice.id!,
                  );
              context.pop();
            },
            variant: HasibButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}
