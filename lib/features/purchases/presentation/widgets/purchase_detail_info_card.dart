import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseDetailInfoCard extends StatelessWidget {
  final InvoiceEntity invoice;

  const PurchaseDetailInfoCard({
    super.key,
    required this.invoice,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date);
  }

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
              'معلومات الفاتورة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            PurchaseInfoRow(
              label: 'رقم الفاتورة',
              value: invoice.number,
              icon: Icons.tag,
            ),
            const SizedBox(height: 12),
            PurchaseInfoRow(
              label: 'التاريخ',
              value: _formatDate(invoice.date),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            PurchaseInfoRow(
              label: 'نوع الدفع',
              value: invoice.invoiceTransType == 0 ? 'نقدي' : 'آجل',
              icon: Icons.payment,
            ),
            if (invoice.dueDate != null) ...[
              const SizedBox(height: 12),
              PurchaseInfoRow(
                label: 'تاريخ الاستحقاق',
                value: _formatDate(invoice.dueDate!),
                icon: Icons.event,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PurchaseInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const PurchaseInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
