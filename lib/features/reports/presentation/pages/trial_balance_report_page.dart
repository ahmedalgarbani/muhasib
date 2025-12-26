import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_state.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_summary_card.dart';

class TrialBalanceReportPage extends StatelessWidget {
  const TrialBalanceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrialBalanceCubit>()..loadTrialBalance(),
      child: ReportBasePage(
        title: 'ميزان المراجعة',
        icon: Icons.balance,
        color: const Color(0xFF1976D2),
        reportBuilder: (filter) => _TrialBalanceContent(filter: filter),
      ),
    );
  }
}

class _TrialBalanceContent extends StatefulWidget {
  final ReportFilter filter;

  const _TrialBalanceContent({required this.filter});

  @override
  State<_TrialBalanceContent> createState() => _TrialBalanceContentState();
}

class _TrialBalanceContentState extends State<_TrialBalanceContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrialBalanceCubit>().updateDateRange(widget.filter);
    });
  }

  @override
  void didUpdateWidget(_TrialBalanceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      context.read<TrialBalanceCubit>().updateDateRange(widget.filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrialBalanceCubit, TrialBalanceState>(
      builder: (context, state) {
        if (state is TrialBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TrialBalanceError) {
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
                    context.read<TrialBalanceCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is TrialBalanceLoaded) {
          final accounts = state.accounts;
          final summary = state.summary;

          if (accounts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 64, color: Colors.grey),
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
                    title: 'إجمالي المدين',
                    value: '${summary.totalDebit.toStringAsFixed(0)} ر.س',
                    icon: Icons.arrow_upward,
                    color: Colors.blue,
                  ),
                  ReportSummaryCard(
                    title: 'إجمالي الدائن',
                    value: '${summary.totalCredit.toStringAsFixed(0)} ر.س',
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                  ReportSummaryCard(
                    title: 'الفرق',
                    value: '${summary.difference.toStringAsFixed(0)} ر.س',
                    icon: Icons.compare_arrows,
                    color: summary.isBalanced ? Colors.green : Colors.red,
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
                                  Expanded(flex: 1, child: Text(account.accountCode, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  Expanded(flex: 3, child: Text(account.accountName)),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      account.debitBalance > 0 ? account.debitBalance.toStringAsFixed(2) : '-',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: account.debitBalance > 0 ? Colors.blue : Colors.grey),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      account.creditBalance > 0 ? account.creditBalance.toStringAsFixed(2) : '-',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: account.creditBalance > 0 ? Colors.green : Colors.grey),
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
                                summary.totalDebit.toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                summary.totalCredit.toStringAsFixed(2),
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

        return const Center(child: Text('لا توجد بيانات'));
      },
    );
  }
}


