import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/invoice_summary_row_widget.dart';

class ImprovedStep4Payment extends StatelessWidget {
  final Invoice invoice;
  final List<Payment> payments;
  final VoidCallback onAddPayment;

  const ImprovedStep4Payment({
    super.key,
    required this.invoice,
    required this.payments,
    required this.onAddPayment,
  });

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bank:
        return 'بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = invoice.total - totalPaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCardContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InvoiceSummaryRowWidget(
                    label: 'الإجمالي المطلوب',
                    amount: invoice.total,
                  ),
                  InvoiceSummaryRowWidget(
                    label: 'المدفوع',
                    amount: totalPaid,
                  ),
                  InvoiceSummaryRowWidget(
                    label: 'المتبقي',
                    amount: remaining,
                    isTotal: true,
                    color: remaining > 0 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          HasibButton(
            label: 'إضافة طريقة دفع',
            onPressed: onAddPayment,
            leading: const Icon(Icons.add),
            variant: HasibButtonVariant.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...payments.map(
              (payment) => CustomCardContainer(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    payment.method == PaymentMethod.cash
                        ? Icons.payments
                        : payment.method == PaymentMethod.bank
                        ? Icons.account_balance
                        : Icons.schedule,
                    color: AppColors.primary,
                  ),
                  title: Text(_getPaymentMethodName(payment.method)),
                  trailing: Text(
                    NumberFormatter.formatCurrency(payment.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
