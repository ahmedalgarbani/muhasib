import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:intl/intl.dart';

/// Enhanced Purchase Summary Report with:
/// 1. Ledger comparison for purchases expense
/// 2. Supplier payables summary
/// 3. Invoice status tracking
/// 4. Cancelled invoice exclusion
class PurchaseSummaryReportPage extends StatelessWidget {
  const PurchaseSummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'ملخص المشتريات',
      icon: Icons.shopping_cart,
      color: const Color(0xFF1976D2),
      reportBuilder: (filter) => _PurchaseSummaryContent(filter: filter),
    );
  }
}

class _PurchaseSummaryContent extends StatelessWidget {
  final ReportFilter filter;
  final _numberFormat = NumberFormat('#,##0.00', 'ar');

  _PurchaseSummaryContent({required this.filter});

  String _formatCurrency(double value) {
    return '${_numberFormat.format(value)} ر.س';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PurchaseSummaryResult>(
      future: _load(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final ledgerDiff = data.netPurchases - data.ledgerPurchases;
        final isMatch = ledgerDiff.abs() < 0.01;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Summary Cards
              _buildMainSummaryCards(data),

              const SizedBox(height: 16),

              // Ledger Comparison
              _buildLedgerComparison(data, isMatch, ledgerDiff),

              const SizedBox(height: 16),

              // Invoice Status
              _buildInvoiceStatusCard(data),

              const SizedBox(height: 16),

              // Financial Breakdown
              _buildFinancialBreakdown(data),

              const SizedBox(height: 16),

              // Top Suppliers
              if (data.topSuppliers.isNotEmpty)
                _buildTopSuppliersCard(data),

              const SizedBox(height: 16),

              // Top Products
              if (data.topProducts.isNotEmpty)
                _buildTopProductsCard(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainSummaryCards(_PurchaseSummaryResult data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryTile('إجمالي المشتريات', data.totalPurchases, Colors.blue, Icons.shopping_cart)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryTile('المرتجعات', data.totalReturns, Colors.orange, Icons.undo)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildSummaryTile('الضرائب', data.totalTaxes, Colors.purple, Icons.receipt)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryTile('الخصومات', data.totalDiscounts, Colors.teal, Icons.local_offer)),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صافي المشتريات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    _formatCurrency(data.netPurchases),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(value), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLedgerComparison(_PurchaseSummaryResult data, bool isMatch, double diff) {
    return Card(
      color: isMatch ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isMatch ? Icons.check_circle : Icons.warning,
                    color: isMatch ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  isMatch ? 'متطابق مع دفتر الأستاذ ✓' : 'تحذير: يوجد فرق مع دفتر الأستاذ!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatch ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صافي المشتريات (الفواتير)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(_formatCurrency(data.netPurchases), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مصروف المشتريات (دفتر الأستاذ)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(_formatCurrency(data.ledgerPurchases), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMatch) ...[
              const SizedBox(height: 8),
              Text(
                'الفرق: ${_formatCurrency(diff.abs())}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
            const Divider(height: 24),
            // Supplier Payables Summary
            Row(
              children: [
                const Icon(Icons.account_balance, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text('إجمالي ذمم الموردين: ', style: TextStyle(color: Colors.grey[600])),
                Text(_formatCurrency(data.supplierPayables), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceStatusCard(_PurchaseSummaryResult data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.purple),
                SizedBox(width: 8),
                Text('حالة الفواتير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _buildStatusRow('فواتير مُرحّلة', data.invoiceCount, Colors.green),
            _buildStatusRow('فواتير مع قيود', data.withJournalEntry, Colors.teal),
            _buildStatusRow('فواتير بدون قيود', data.withoutJournalEntry, 
                data.withoutJournalEntry > 0 ? Colors.red : Colors.grey),
            if (data.withoutJournalEntry > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يوجد فواتير بدون قيود محاسبية!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdown(_PurchaseSummaryResult data) {
    final totalPurchases = data.totalPurchases;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text('التحليل المالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _buildBreakdownRow('عدد الفواتير', '${data.invoiceCount}'),
            _buildBreakdownRow('عدد المرتجعات', '${data.returnCount}'),
            _buildBreakdownRow('عدد الموردين', '${data.supplierCount}'),
            const Divider(),
            _buildBreakdownRow('نسبة المرتجعات', 
                '${totalPurchases > 0 ? (data.totalReturns / totalPurchases * 100).toStringAsFixed(1) : 0}%'),
            _buildBreakdownRow('متوسط الفاتورة',
                _formatCurrency(data.invoiceCount > 0 ? data.totalPurchases / data.invoiceCount : 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopSuppliersCard(_PurchaseSummaryResult data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.local_shipping, color: Colors.blue),
        title: const Text('أكثر الموردين تعاملاً'),
        children: [
          ...data.topSuppliers.take(10).map((s) => ListTile(
            dense: true,
            title: Text(s.name),
            subtitle: Text('عدد الفواتير: ${s.invoiceCount}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(s.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('الذمة: ${_formatCurrency(s.balance)}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(_PurchaseSummaryResult data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.category, color: Colors.purple),
        title: const Text('أكثر الأصناف شراءً'),
        children: [
          ...data.topProducts.take(10).map((p) => ListTile(
            dense: true,
            title: Text(p.name),
            subtitle: Text('الكمية: ${p.quantity.toStringAsFixed(0)}'),
            trailing: Text(_formatCurrency(p.total), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Future<_PurchaseSummaryResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String dateFilter = '';
    if (filter.startDate != null && filter.endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    // Main totals - excluding cancelled invoices
    final totals = await db.rawQuery('''
      SELECT
        COUNT(CASE WHEN i.invoice_type = 2 THEN 1 END) as invoice_count,
        COUNT(CASE WHEN i.invoice_type = 5 THEN 1 END) as return_count,
        COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as total_purchases,
        COALESCE(SUM(CASE WHEN i.invoice_type = 5 THEN COALESCE(i.final_amt, i.total_amount, i.amount, 0) END), 0) as total_returns,
        COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.tax_amt, 0) END), 0) as total_taxes,
        COALESCE(SUM(CASE WHEN i.invoice_type = 2 THEN COALESCE(i.discount_amt, 0) END), 0) as total_discounts,
        COUNT(DISTINCT i.customer_id) as supplier_count
      FROM invoices i
      WHERE (i.invoice_type = 2 OR i.invoice_type = 5)
        AND COALESCE(i.status, 1) != 3
      $dateFilter
    ''', args);

    final totalPurchases = (totals.first['total_purchases'] as num?)?.toDouble() ?? 0.0;
    final totalReturns = (totals.first['total_returns'] as num?)?.toDouble() ?? 0.0;
    final totalTaxes = (totals.first['total_taxes'] as num?)?.toDouble() ?? 0.0;
    final totalDiscounts = (totals.first['total_discounts'] as num?)?.toDouble() ?? 0.0;
    final invoiceCount = (totals.first['invoice_count'] ?? 0) as int;
    final returnCount = (totals.first['return_count'] ?? 0) as int;
    final supplierCount = (totals.first['supplier_count'] ?? 0) as int;

    // Ledger comparison - get purchase expense from journal
    String jeDateFilter = '';
    final jeArgs = <Object?>[];
    if (filter.startDate != null && filter.endDate != null) {
      jeDateFilter = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      jeArgs.add(filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      jeArgs.add(filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final ledgerResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as purchases
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE je.is_posted = 1 
        AND (a.type = 4 OR a.code LIKE '31%')
        AND je.reference_type LIKE '%purchase%'
        $jeDateFilter
    ''', jeArgs);
    final ledgerPurchases = (ledgerResult.first['purchases'] as num?)?.toDouble() ?? 0.0;

    // Supplier payables
    final payablesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(current_balance), 0) as payables
      FROM customers
      WHERE type = 1
    ''');
    final supplierPayables = (payablesResult.first['payables'] as num?)?.toDouble() ?? 0.0;

    // Invoices with/without journal entries
    final statusResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN EXISTS (
          SELECT 1 FROM journal_entries je 
          WHERE je.reference_type = 'purchase_invoice' AND je.reference_id = i.id
        ) THEN 1 END) as with_entry
      FROM invoices i
      WHERE invoice_type = 2
        AND COALESCE(status, 1) != 3
        $dateFilter
    ''', args);
    final totalInvoices = (statusResult.first['total'] as int?) ?? 0;
    final withEntry = (statusResult.first['with_entry'] as int?) ?? 0;

    // Top suppliers with balance
    final topSuppliers = await db.rawQuery('''
      SELECT
        c.id,
        c.name,
        COUNT(i.id) as invoice_count,
        COALESCE(SUM(COALESCE(i.final_amt, i.total_amount, i.amount, 0)), 0) as total,
        COALESCE(c.current_balance, 0) as balance
      FROM invoices i
      INNER JOIN customers c ON c.id = i.customer_id
      WHERE i.invoice_type = 2
        AND COALESCE(i.status, 1) != 3
      $dateFilter
      GROUP BY c.id, c.name
      ORDER BY total DESC
      LIMIT 10
    ''', args);

    // Top products with quantity
    final topProducts = await db.rawQuery('''
      SELECT
        cat.name,
        COALESCE(SUM(il.quantity), 0) as quantity,
        COALESCE(SUM(il.total_amount), 0) as total
      FROM invoice_lines il
      INNER JOIN invoices i ON i.id = il.invoice_id
      LEFT JOIN categories cat ON cat.id = il.category_id
      WHERE i.invoice_type = 2
        AND COALESCE(i.status, 1) != 3
      $dateFilter
      GROUP BY cat.id, cat.name
      ORDER BY total DESC
      LIMIT 10
    ''', args);

    return _PurchaseSummaryResult(
      totalPurchases: totalPurchases,
      totalReturns: totalReturns,
      totalTaxes: totalTaxes,
      totalDiscounts: totalDiscounts,
      invoiceCount: invoiceCount,
      returnCount: returnCount,
      supplierCount: supplierCount,
      ledgerPurchases: ledgerPurchases,
      supplierPayables: supplierPayables,
      withJournalEntry: withEntry,
      withoutJournalEntry: totalInvoices - withEntry,
      topSuppliers: topSuppliers.map((m) => _SupplierRow(
        name: (m['name'] as String?) ?? '',
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
        balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
        invoiceCount: (m['invoice_count'] as int?) ?? 0,
      )).toList(),
      topProducts: topProducts.map((m) => _ProductRow(
        name: (m['name'] as String?) ?? '',
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
      )).toList(),
    );
  }
}

class _PurchaseSummaryResult {
  final double totalPurchases;
  final double totalReturns;
  final double totalTaxes;
  final double totalDiscounts;
  final int invoiceCount;
  final int returnCount;
  final int supplierCount;
  final double ledgerPurchases;
  final double supplierPayables;
  final int withJournalEntry;
  final int withoutJournalEntry;
  final List<_SupplierRow> topSuppliers;
  final List<_ProductRow> topProducts;

  const _PurchaseSummaryResult({
    required this.totalPurchases,
    required this.totalReturns,
    required this.totalTaxes,
    required this.totalDiscounts,
    required this.invoiceCount,
    required this.returnCount,
    required this.supplierCount,
    required this.ledgerPurchases,
    required this.supplierPayables,
    required this.withJournalEntry,
    required this.withoutJournalEntry,
    required this.topSuppliers,
    required this.topProducts,
  });

  double get netPurchases => totalPurchases - totalReturns;
}

class _SupplierRow {
  final String name;
  final double total;
  final double balance;
  final int invoiceCount;
  const _SupplierRow({required this.name, required this.total, required this.balance, required this.invoiceCount});
}

class _ProductRow {
  final String name;
  final double total;
  final double quantity;
  const _ProductRow({required this.name, required this.total, required this.quantity});
}
