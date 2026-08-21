import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/enums/invoice_payment_status.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';

class PurchaseDetailHeader extends StatelessWidget {
  final InvoiceEntity invoice;

  const PurchaseDetailHeader({
    super.key,
    required this.invoice,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فاتورة مشتريات #${invoice.number}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(invoice.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          PurchaseStatusChip(paymentStatus: invoice.paymentStatus),
        ],
      ),
    );
  }
}

class PurchaseStatusChip extends StatelessWidget {
  final int paymentStatus;

  const PurchaseStatusChip({
    super.key,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = InvoicePaymentStatus.tryFromValue(paymentStatus) ?? InvoicePaymentStatus.unpaid;
    final (String text, Color color, IconData icon) = switch (status) {
      InvoicePaymentStatus.paid => ('مدفوعة', Colors.green, Icons.check_circle),
      InvoicePaymentStatus.partial => ('مدفوعة جزئياً', Colors.orange, Icons.timelapse),
      InvoicePaymentStatus.unpaid => ('غير مدفوعة', Colors.red, Icons.cancel),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
