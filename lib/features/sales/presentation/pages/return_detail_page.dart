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
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildOriginalInvoiceCard(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildReturnedProductsCard(),
            const SizedBox(height: 16),
            _buildTotalsCard(),
            const SizedBox(height: 16),
            _buildAccountingEntriesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فاتورة مرتجع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      returnInvoice.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                InvoiceTypeBadge(type: InvoiceType.salesReturn),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'تاريخ المرتجع',
                    _formatDate(returnInvoice.date),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'المستودع',
                    'مستودع #${returnInvoice.stockId}',
                    Icons.warehouse,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalInvoiceCard() {
    return CustomCardContainer(
      elevation: 0,
      color: AppColors.amber100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.warning, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.amber800,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'الفاتورة الأصلية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'رقم الفاتورة: ${returnInvoice.parentInvoiceNumber ?? "غير محدد"}',
              style: const TextStyle(fontSize: 14, color: AppColors.amber800),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to original invoice
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber800,
                side: const BorderSide(color: AppColors.amber800),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('عرض الفاتورة الأصلية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات العميل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'العميل',
              'عميل #${returnInvoice.customerId}',
              Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnedProductsCard() {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المنتجات المرتجعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: returnInvoice.lines.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final line = returnInvoice.lines[index];
                return _buildProductLine(line);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductLine(dynamic line) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Center(
            child: Icon(
              Icons.assignment_return,
              size: 20,
              color: AppColors.error,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'منتج #${line.categoryId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الكمية المرتجعة: ${line.quantity} × ${_formatCurrency(line.amount)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(line.totalAmount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard() {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('المجموع الفرعي', returnInvoice.amount),
            if (returnInvoice.taxAmt != null && returnInvoice.taxAmt! > 0) ...[
              const SizedBox(height: 12),
              _buildTotalRow('الضريبة', returnInvoice.taxAmt!),
            ],
            const Divider(height: 24),
            _buildTotalRow(
              'إجمالي المرتجع',
              returnInvoice.finalAmt ?? returnInvoice.amount,
              isFinal: true,
            ),
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

  Widget _buildAccountingEntriesCard() {
    // Generate accounting entries preview
    final template = SalesAccountingTemplate();

    // Create sample accounting entries
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadReturnEntries(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'entries': <Map<String, dynamic>>[],
              'total_debit': 0.0,
              'total_credit': 0.0,
            };

        final isBalanced = template.validateEntries(data);

        return CustomCardContainer(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'القيود المحاسبية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isBalanced
                            ? AppColors.emerald100
                            : AppColors.red100,
                        borderRadius: BorderRadius.circular(AppRadius.sm6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBalanced ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: isBalanced
                                ? AppColors.emerald800
                                : AppColors.red800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBalanced ? 'متوازن' : 'غير متوازن',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBalanced
                                  ? AppColors.emerald800
                                  : AppColors.red800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildAccountingEntryRows(data['entries'] as List),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجماليات:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'مدين: ${_formatCurrency(data['total_debit'] as double)} | دائن: ${_formatCurrency(data['total_credit'] as double)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAccountingEntryRows(List<dynamic> entries) {
    return entries.map((entry) {
      final debit = entry['debit'] as double;
      final credit = entry['credit'] as double;
      final accountName = entry['account_name'] as String;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                debit > 0 ? 'من ح/ $accountName' : 'إلى ح/ $accountName',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Text(
              _formatCurrency(debit > 0 ? debit : credit),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: debit > 0 ? AppColors.emerald600 : AppColors.red600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
            color: isFinal ? AppColors.gray900 : Colors.grey.shade700,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isFinal ? 20 : 14,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ],
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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ريال';
  }
}
