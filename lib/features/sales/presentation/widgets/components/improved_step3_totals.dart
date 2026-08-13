import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/invoice_summary_row_widget.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ImprovedStep3Totals extends StatelessWidget {
  final Invoice invoice;

  const ImprovedStep3Totals({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppConstant.defaultPadding,
      child: Column(
        children: [
          CustomCardContainer(
            child: Padding(
              padding: AppConstant.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص الفاتورة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  InvoiceSummaryRowWidget(
                    label: 'المجموع الفرعي',
                    amount: invoice.subtotal,
                  ),
                  InvoiceSummaryRowWidget(
                    label: 'الخصم',
                    amount: invoice.discountAmount,
                  ),
                  InvoiceSummaryRowWidget(
                    label: 'الضريبة (15%)',
                    amount: invoice.subtotal * 0.15,
                  ),
                  const Divider(),
                  InvoiceSummaryRowWidget(
                    label: 'الإجمالي',
                    amount: invoice.total,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
