import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/purchases/presentation/widgets/invoice_total_row.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseDetailTotalsCard extends StatelessWidget {
  final InvoiceEntity invoice;

  const PurchaseDetailTotalsCard({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الإجماليات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            InvoiceTotalRow(
              label: 'المجموع الفرعي',
              amount: invoice.amount,
            ),
            if (invoice.discountAmt != null && invoice.discountAmt! > 0) ...[
              const SizedBox(height: 8),
              InvoiceTotalRow(
                label: 'الخصم',
                amount: -invoice.discountAmt!,
                color: Colors.orange,
              ),
            ],
            if (invoice.taxAmt != null && invoice.taxAmt! > 0) ...[
              const SizedBox(height: 8),
              InvoiceTotalRow(
                label: 'الضريبة (${invoice.taxRatio ?? 0}%)',
                amount: invoice.taxAmt!,
                color: Colors.blue,
              ),
            ],
            const Divider(height: 24),
            InvoiceTotalRow(
              label: 'الإجمالي النهائي',
              amount: invoice.finalAmt ?? invoice.amount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}
