import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/widgets/constants/invoice_ui_constants.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/sales_invoice_screen.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

import 'package:muhasib/features/sales/presentation/widgets/components/quotation_card_widget.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/quotation_filter_bar_widget.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/quotation_header_widget.dart';

class QuotationsPage extends StatefulWidget {
  const QuotationsPage({super.key});

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOnlyOpen = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  void _loadQuotations() {
    if (_showOnlyOpen) {
      context.read<SalesCubit>().loadOpenQuotations();
    } else {
      context.read<SalesCubit>().loadQuotations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.gray50,
      appBar: CustomAppBar(),
      body: Column(
        children: [
          QuotationHeaderWidget(
            searchController: _searchController,
            onRefresh: _loadQuotations,
            onChanged: (value) {
              // Implement search logic
            },
          ),
          QuotationFilterBarWidget(
            showOnlyOpen: _showOnlyOpen,
            onFilterChanged: (onlyOpen) {
              setState(() {
                _showOnlyOpen = onlyOpen;
                _loadQuotations();
              });
            },
          ),
          Expanded(
            child: BlocConsumer<SalesCubit, SalesState>(
              listener: (context, state) {
                if (state is SalesError) {
                  AppToast.showError(context, state.message);
                } else if (state is QuotationConverted) {
                  AppToast.showSuccess(
                    context,
                    'تم تحويل عرض السعر إلى فاتورة بنجاح',
                  );
                  _loadQuotations();
                }
              },
              builder: (context, state) {
                if (state is SalesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is QuotationsLoaded) {
                  if (state.quotations.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'لا توجد عروض أسعار',
                      subtitle: 'ابدأ بإنشاء عرض سعر جديد',
                      icon: Icons.request_quote_outlined,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadQuotations();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.quotations.length,
                      itemBuilder: (context, index) {
                        final quotation = state.quotations[index];
                        return QuotationCardWidget(
                          quotation: quotation,
                          onConvert: () => _showConvertDialog(quotation),
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('ابدأ بتحميل عروض الأسعار'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => getIt<SalesCubit>()),
                  BlocProvider(create: (_) => getIt<CustomersCubit>()),
                  BlocProvider(create: (_) => getIt<ProductsCubit>()),
                ],
                child: const SalesInvoiceScreen(
                  invoiceType: InvoiceType.quotation,
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('عرض سعر جديد'),
      ),
    );
  }

  void _showConvertDialog(InvoiceEntity quotation) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: const Row(
          children: [
            Icon(Icons.transform, color: AppColors.success),
            SizedBox(width: 8),
            Text('تحويل عرض السعر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تحويل عرض السعر ${quotation.number} إلى فاتورة مبيعات؟',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم إنشاء فاتورة مبيعات جديدة بنفس البيانات',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'تأكيد التحويل',
            onPressed: () {
              Navigator.pop(dialogContext);

              // Generate proper invoice number with timestamp
              final now = DateTime.now();
              final invoiceNumber =
                  'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';

              // Create sales invoice from quotation
              final salesInvoice = quotation.copyWith(
                id: null, // Clear ID so a new one is generated
                invoiceType: InvoiceType.salesInvoice.value,
                number: invoiceNumber,
                date: now.millisecondsSinceEpoch ~/ 1000,
                parentInvoiceId: quotation.id,
                parentInvoiceNumber: quotation.number,
                paymentStatus: 0, // Reset payment status
                nextInvoiceId: null,
                nextInvoiceType: null,
                nextInvoiceNumber: null,
              );

              context.read<SalesCubit>().convertQuotation(
                quotation.id!,
                salesInvoice,
              );
            },
            icon: Icons.check,
            variant: HasibButtonVariant.success,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}


// Extension to add copyWith to InvoiceEntity
extension InvoiceEntityExtension on InvoiceEntity {
  InvoiceEntity copyWith({
    int? id,
    int? invoiceType,
    String? number,
    int? date,
    String? statement,
    double? amount,
    double? finalAmt,
    int? customerId,
    int? stockId,
    int? invoiceTransType,
    int? parentInvoiceId,
    String? parentInvoiceNumber,
    int? paymentStatus,
    int? nextInvoiceId,
    int? nextInvoiceType,
    String? nextInvoiceNumber,
    List<InvoiceLineEntity>? lines,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceType: invoiceType ?? this.invoiceType,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      amount: amount ?? this.amount,
      totalAmount: totalAmount,
      taxAmt: taxAmt,
      taxRatio: taxRatio,
      discountAmt: discountAmt,
      discountRatio: discountRatio,
      otherFeeAmt: otherFeeAmt,
      otherFeeNetRatio: otherFeeNetRatio,
      netRevenueAmt: netRevenueAmt,
      totalAmountAfterDiscount: totalAmountAfterDiscount,
      finalAmt: finalAmt ?? this.finalAmt,
      currencyId: currencyId,
      stockId: stockId ?? this.stockId,
      customerId: customerId ?? this.customerId,
      taxId: taxId,
      otherFeeAccountId: otherFeeAccountId,
      invoiceTransType: invoiceTransType ?? this.invoiceTransType,
      parentInvoiceId: parentInvoiceId ?? this.parentInvoiceId,
      parentInvoiceNumber: parentInvoiceNumber ?? this.parentInvoiceNumber,
      nextInvoiceType: nextInvoiceType ?? this.nextInvoiceType,
      nextInvoiceId: nextInvoiceId ?? this.nextInvoiceId,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      uNo: uNo,
      currencyCode: currencyCode,
      exchangeRate: exchangeRate,
      imagePath: imagePath,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingAddress: shippingAddress,
      dueDate: dueDate,
      lines: lines ?? this.lines,
    );
  }
}
