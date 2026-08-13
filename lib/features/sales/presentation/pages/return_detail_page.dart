import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/domain/templates/sales_accounting_template.dart';
import 'package:muhasib/features/sales/presentation/widgets/constants/invoice_ui_constants.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

import 'package:muhasib/features/sales/presentation/widgets/components/return_detail_components.dart';

/// Return Invoice Detail Page
/// Displays complete return information with accounting entries preview
class ReturnDetailPage extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailPage({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: CustomAppBar(
        title: returnInvoice.number,
        actions: [
          IconButton(
            onPressed: () {
              _showPrintOptions(context);
            },
            icon: const Icon(Icons.print),
            tooltip: 'طباعة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReturnDetailHeaderCard(returnInvoice: returnInvoice),
            const SizedBox(height: 16),
            ReturnDetailOriginalInvoiceCard(
              returnInvoice: returnInvoice,
              onViewOriginal: () {
                // Navigate to original invoice
              },
            ),
            const SizedBox(height: 16),
            ReturnDetailCustomerCard(returnInvoice: returnInvoice),
            const SizedBox(height: 16),
            ReturnDetailProductsCard(returnInvoice: returnInvoice),
            const SizedBox(height: 16),
            ReturnDetailTotalsCard(returnInvoice: returnInvoice),
            const SizedBox(height: 16),
            ReturnDetailAccountingCard(entriesFuture: _loadReturnEntries()),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadReturnEntries() async {
    final template = SalesAccountingTemplate();
    final db = await DatabaseService().database;
    final ids = returnInvoice.lines
        .map((e) => e.categoryId)
        .whereType<int>()
        .toSet()
        .toList();

    final Map<int, Map<String, dynamic>> categories = {};
    if (ids.isNotEmpty) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT id, name, cost_amount FROM categories WHERE id IN ($placeholders)',
        ids,
      );
      for (final row in rows) {
        final id = row['id'] as int;
        categories[id] = row;
      }
    }

    final invoiceLines = returnInvoice.lines.map((line) {
      final cid = line.categoryId ?? 0;
      final name = (categories[cid]?['name'] as String?) ?? 'منتج #$cid';
      final cost = (categories[cid]?['cost_amount'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = line.amount;
      return InvoiceLineEntry.fromInvoiceLine(
        categoryId: cid,
        productName: name,
        quantity: line.quantity,
        unitPrice: unitPrice,
        costPerUnit: cost,
      );
    }).toList();

    return template.generateSalesReturnEntries(
      customerId: returnInvoice.customerId,
      customerName: 'عميل #${returnInvoice.customerId}',
      returnNumber: returnInvoice.number,
      originalInvoiceNumber: returnInvoice.parentInvoiceNumber ?? 'N/A',
      returnDate: returnInvoice.date,
      totalAmount: returnInvoice.finalAmt ?? returnInvoice.amount,
      taxAmount: returnInvoice.taxAmt ?? 0,
      netAmount: returnInvoice.amount,
      lines: invoiceLines,
    );
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('تصدير PDF'),
              onTap: () {
                Navigator.pop(context);
                // Export to PDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة'),
              onTap: () {
                Navigator.pop(context);
                // Print
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                // Share
              },
            ),
          ],
        ),
      ),
    );
  }
}

