import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class TrialBalanceReportPage extends StatelessWidget {
  const TrialBalanceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'ميزان المراجعة',
      icon: Icons.balance,
      color: const Color(0xFF1976D2),
      reportBuilder: (filter) => _TrialBalanceContent(filter: filter),
    );
  }
}

class _TrialBalanceContent extends StatelessWidget {
  final ReportFilter filter;

  const _TrialBalanceContent({required this.filter});

  @override
  Widget build(BuildContext context) {
    // Demo data - في التطبيق الحقيقي سيتم جلب البيانات من قاعدة البيانات
    final accounts = [
      _TrialBalanceRow('1110', 'الصندوق', 50000, 0),
      _TrialBalanceRow('1120', 'البنك', 150000, 0),
      _TrialBalanceRow('1210', 'العملاء', 75000, 0),
      _TrialBalanceRow('1310', 'المخزون', 200000, 0),
      _TrialBalanceRow('2110', 'الموردين', 0, 85000),
      _TrialBalanceRow('2210', 'قروض بنكية', 0, 100000),
      _TrialBalanceRow('3110', 'رأس المال', 0, 250000),
      _TrialBalanceRow('4110', 'إيرادات المبيعات', 0, 180000),
      _TrialBalanceRow('5110', 'تكلفة المبيعات', 120000, 0),
      _TrialBalanceRow('5210', 'مصاريف إدارية', 20000, 0),
    ];

    final totalDebit = accounts.fold<double>(0, (sum, a) => sum + a.debit);
    final totalCredit = accounts.fold<double>(0, (sum, a) => sum + a.credit);

    return Column(
      children: [
        // Summary cards
        ReportSummaryRow(
          cards: [
            ReportSummaryCard(
              title: 'إجمالي المدين',
              value: '${totalDebit.toStringAsFixed(0)} ر.س',
              icon: Icons.arrow_upward,
              color: Colors.blue,
            ),
            ReportSummaryCard(
              title: 'إجمالي الدائن',
              value: '${totalCredit.toStringAsFixed(0)} ر.س',
              icon: Icons.arrow_downward,
              color: Colors.green,
            ),
            ReportSummaryCard(
              title: 'الفرق',
              value: '${(totalDebit - totalCredit).toStringAsFixed(0)} ر.س',
              icon: Icons.compare_arrows,
              color: (totalDebit - totalCredit).abs() < 0.01 ? Colors.green : Colors.red,
            ),
          ],
        ),

        // Table
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 1, child: Text('رقم الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('اسم الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('مدين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('دائن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                ),

                // Rows
                Expanded(
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: index.isEven ? Colors.grey[50] : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(account.code, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Expanded(flex: 3, child: Text(account.name)),
                            Expanded(
                              flex: 2,
                              child: Text(
                                account.debit > 0 ? account.debit.toStringAsFixed(2) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: account.debit > 0 ? Colors.blue : Colors.grey),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                account.credit > 0 ? account.credit.toStringAsFixed(2) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: account.credit > 0 ? Colors.green : Colors.grey),
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
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 4, child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalDebit.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalCredit.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
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

class _TrialBalanceRow {
  final String code;
  final String name;
  final double debit;
  final double credit;

  _TrialBalanceRow(this.code, this.name, this.debit, this.credit);
}

