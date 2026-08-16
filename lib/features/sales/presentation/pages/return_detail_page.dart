import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/templates/sales_accounting_template.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/return_detail_components.dart';

/// Return Invoice Detail Page
/// Displays complete return information with accounting entries preview
class ReturnDetailPage extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const ReturnDetailPage({super.key, required this.returnInvoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        padding: AppConstant.defaultPadding,
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
    final productRepo = getIt<ProductRepository>();

    final productMap = <int, ProductEntity>{};
    final productResult = await productRepo.getProducts();
    productResult.fold((_) => null, (products) {
      for (final p in products) {
        if (p.id != null) productMap[p.id!] = p;
      }
    });

    final invoiceLines = returnInvoice.lines.map((line) {
      final cid = line.categoryId ?? 0;
      final product = productMap[cid];
      final name = product?.name ?? 'منتج #$cid';
      final cost = product?.costAmount ?? 0.0;
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

