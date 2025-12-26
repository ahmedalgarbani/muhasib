import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class AccountStatementReportPage extends StatelessWidget {
  const AccountStatementReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AccountStatementCubit>()..loadAccounts(),
      child: Builder(
        builder: (context) => ReportBasePage(
          title: 'كشف حساب',
          icon: Icons.receipt_long,
          color: const Color(0xFFFF5722),
          additionalFilters: [
            _buildAccountSelector(context),
          ],
          reportBuilder: (filter) => _AccountStatementContent(filter: filter),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
    return BlocBuilder<AccountStatementCubit, AccountStatementState>(
      builder: (context, state) {
        if (state is AccountStatementLoaded) {
          return DropdownButtonFormField<int>(
            value: state.selectedAccountId,
            decoration: InputDecoration(
              labelText: 'اختر الحساب',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: state.accounts.map((account) {
              return DropdownMenuItem(
                value: account['id'] as int,
                child: Text('${account['code']} - ${account['name']}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<AccountStatementCubit>().selectAccount(value);
              }
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AccountStatementContent extends StatefulWidget {
  final ReportFilter filter;

  const _AccountStatementContent({required this.filter});

  @override
  State<_AccountStatementContent> createState() => _AccountStatementContentState();
}

class _AccountStatementContentState extends State<_AccountStatementContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountStatementCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_AccountStatementContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<AccountStatementCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountStatementCubit, AccountStatementState>(
      builder: (context, state) {
        if (state is AccountStatementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountStatementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطأ: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AccountStatementCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is AccountStatementLoaded) {
          final transactions = state.transactions;
          final summary = state.summary;

          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد حركات في الفترة المحددة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary cards
              ReportSummaryRow(
                cards: [
                  ReportSummaryCard(
                    title: 'الرصيد الافتتاحي',
                    value: '${summary.openingBalance.toStringAsFixed(0)} ر.س',
                    icon: Icons.play_arrow,
                    color: Colors.blue,
                  ),
                  ReportSummaryCard(
                    title: 'إجمالي المدين',
                    value: '${summary.totalDebits.toStringAsFixed(0)} ر.س',
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                  ),
                  ReportSummaryCard(
                    title: 'إجمالي الدائن',
                    value: '${summary.totalCredits.toStringAsFixed(0)} ر.س',
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                  ),
                  ReportSummaryCard(
                    title: 'الرصيد الختامي',
                    value: '${summary.closingBalance.toStringAsFixed(0)} ر.س',
                    icon: Icons.stop,
                    color: summary.closingBalance >= 0 ? Colors.purple : Colors.red,
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
                                '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
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
                                t.debitAmount > 0 ? t.debitAmount.toStringAsFixed(0) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: t.debitAmount > 0 ? Colors.green : Colors.grey),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                t.creditAmount > 0 ? t.creditAmount.toStringAsFixed(0) : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: t.creditAmount > 0 ? Colors.red : Colors.grey),
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
                          summary.totalDebits.toStringAsFixed(0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          summary.totalCredits.toStringAsFixed(0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          summary.closingBalance.toStringAsFixed(0),
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

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }
}

