import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class AccountStatementReportPage extends StatelessWidget {
  const AccountStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'كشف حساب',
      icon: Icons.receipt_long,
      color: const Color(0xFFFF5722),
      additionalFilters: [
        _buildAccountSelector(),
      ],
      reportBuilder: (filter) => _AccountStatementContent(filter: filter),
    );
  }

  Widget _buildAccountSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'اختر الحساب',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: '1110', child: Text('1110 - الصندوق')),
        DropdownMenuItem(value: '1120', child: Text('1120 - البنك')),
        DropdownMenuItem(value: '1210', child: Text('1210 - العملاء')),
        DropdownMenuItem(value: '2110', child: Text('2110 - الموردين')),
      ],
      onChanged: (value) {},
    );
  }
}

class _AccountStatementContent extends StatelessWidget {
  final ReportFilter filter;

  const _AccountStatementContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      _Transaction(DateTime(2024, 1, 1), 'رصيد افتتاحي', '', 50000, 0, 50000),
      _Transaction(DateTime(2024, 1, 5), 'فاتورة مبيعات #001', 'INV-001', 15000, 0, 65000),
      _Transaction(DateTime(2024, 1, 8), 'سداد عميل', 'REC-001', 0, 10000, 55000),
      _Transaction(DateTime(2024, 1, 12), 'فاتورة مبيعات #002', 'INV-002', 22000, 0, 77000),
      _Transaction(DateTime(2024, 1, 15), 'مرتجع مبيعات', 'RET-001', 0, 3000, 74000),
      _Transaction(DateTime(2024, 1, 20), 'سداد عميل', 'REC-002', 0, 20000, 54000),
      _Transaction(DateTime(2024, 1, 25), 'فاتورة مبيعات #003', 'INV-003', 18500, 0, 72500),
    ];

    final totalDebit = transactions.fold<double>(0, (sum, t) => sum + t.debit);
    final totalCredit = transactions.fold<double>(0, (sum, t) => sum + t.credit);

    return Column(
      children: [
        // Summary cards
        ReportSummaryRow(
          cards: [
            ReportSummaryCard(
              title: 'الرصيد الافتتاحي',
              value: '50,000 ر.س',
              icon: Icons.play_arrow,
              color: Colors.blue,
            ),
            ReportSummaryCard(
              title: 'إجمالي المدين',
              value: '${totalDebit.toStringAsFixed(0)} ر.س',
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
            ReportSummaryCard(
              title: 'إجمالي الدائن',
              value: '${totalCredit.toStringAsFixed(0)} ر.س',
              icon: Icons.arrow_downward,
              color: Colors.red,
            ),
            ReportSummaryCard(
              title: 'الرصيد الختامي',
              value: '72,500 ر.س',
              icon: Icons.stop,
              color: Colors.purple,
            ),
          ],
        ),

        // Transactions table
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5722),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('البيان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('مدين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('دائن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('الرصيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                ),

                // Rows
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: index.isEven ? Colors.grey[50] : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${t.date.day}/${t.date.month}/${t.date.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  if (t.reference.isNotEmpty)
                                    Text(t.reference, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.debit > 0 ? t.debit.toStringAsFixed(0) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: t.debit > 0 ? Colors.green : Colors.grey),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.credit > 0 ? t.credit.toStringAsFixed(0) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: t.credit > 0 ? Colors.red : Colors.grey),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.balance.toStringAsFixed(0),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 5, child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalDebit.toStringAsFixed(0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalCredit.toStringAsFixed(0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '72,500',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Transaction {
  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final double balance;

  _Transaction(this.date, this.description, this.reference, this.debit, this.credit, this.balance);
}

