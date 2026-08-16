import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/data/report_date_utils.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class GeneralLedgerReportPage extends StatefulWidget {
  const GeneralLedgerReportPage({super.key});
  @override
  State<GeneralLedgerReportPage> createState() =>
      _GeneralLedgerReportPageState();
}

class _GeneralLedgerReportPageState extends State<GeneralLedgerReportPage> {
  _LedgerResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'دفتر الأستاذ العام',
      icon: Icons.menu_book,
      color: AppColors.brown700,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _GeneralLedgerContent(
        filter: filter,
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final List<List<String>> data = [];
    for (var acc in _lastResult!.accounts) {
      data.add([
        acc.code,
        acc.name,
        acc.totalDebit.toStringAsFixed(2),
        acc.totalCredit.toStringAsFixed(2),
        acc.balance.toStringAsFixed(2),
      ]);
    }
    await ExportService.printData(
      title: 'دفتر الأستاذ العام',
      headers: ['الكود', 'الحساب', 'مدين', 'دائن', 'الرصيد'],
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final path = await ExportService.exportToExcel(
      fileName: 'general_ledger',
      headers: ['كود', 'اسم الحساب', 'إجمالي مدين', 'إجمالي دائن', 'الرصيد'],
      data: _lastResult!.accounts
          .map(
            (a) => [
              a.code,
              a.name,
              a.totalDebit.toStringAsFixed(2),
              a.totalCredit.toStringAsFixed(2),
              a.balance.toStringAsFixed(2),
            ],
          )
          .toList(),
    );
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _GeneralLedgerContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_LedgerResult) onLoad;
  const _GeneralLedgerContent({required this.filter, required this.onLoad});
  @override
  State<_GeneralLedgerContent> createState() => _GeneralLedgerContentState();
}

class _GeneralLedgerContentState extends State<_GeneralLedgerContent> {
  int? _selectedAccountId;
  late Future<_LedgerResult> _future;
  _LedgerResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _GeneralLedgerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LedgerResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLoad(data);
          });
        }
        if (data == null || data.accounts.isEmpty) {
          return const Center(child: Text('لا توجد بيانات للفترة المحددة'));
        }

        var accounts = data.accounts;
        if (widget.filter.searchQuery != null &&
            widget.filter.searchQuery!.isNotEmpty) {
          final q = widget.filter.searchQuery!.toLowerCase();
          accounts = accounts
              .where(
                (a) =>
                    a.code.toLowerCase().contains(q) ||
                    a.name.toLowerCase().contains(q),
              )
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: AppConstant.defaultPadding,
              child: Row(
                children: [
                  Expanded(
                    child: ReportKpiCard(
                      title: 'إجمالي الحركات المدينة',
                      value: NumberFormatter.formatCurrency(
                        data.totalDebit,
                        symbol: 'ر.س',
                      ),
                      icon: Icons.arrow_upward,
                      color: Colors.blue[700]!,
                      subtitle: 'جميع القيود المدينة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReportKpiCard(
                      title: 'إجمالي الحركات الدائنة',
                      value: NumberFormatter.formatCurrency(
                        data.totalCredit,
                        symbol: 'ر.س',
                      ),
                      icon: Icons.arrow_downward,
                      color: Colors.green[700]!,
                      subtitle: 'جميع القيود الدائنة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReportKpiCard(
                      title: 'صافي فرق الأستاذ',
                      value: NumberFormatter.formatCurrency(
                        (data.totalDebit - data.totalCredit).abs(),
                        symbol: 'ر.س',
                      ),
                      icon: Icons.balance,
                      color: (data.totalDebit - data.totalCredit).abs() < 0.01
                          ? Colors.teal[700]!
                          : Colors.red[700]!,
                      subtitle:
                          (data.totalDebit - data.totalCredit).abs() < 0.01
                          ? 'متوازن ✓'
                          : 'غير متوازن ⚠',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final a = accounts[index];
                  final isSel = _selectedAccountId == a.id;
                  return CustomCardContainer(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      key: PageStorageKey('acc_${a.id}'),
                      onExpansionChanged: (v) {
                        setState(() => _selectedAccountId = v ? a.id : null);
                      },
                      leading: Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _getAccountTypeColor(a.type),
                          borderRadius: BorderRadius.circular(AppRadius.xxs),
                        ),
                      ),
                      title: Text(
                        '${a.code} - ${a.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'الرصيد: ${NumberFormatter.formatCurrency(a.balance, symbol: 'ر.س')}',
                        style: TextStyle(
                          color: a.balance >= 0 ? Colors.blue : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        if (isSel)
                          _AccountTransactionsView(
                            accountId: a.id,
                            accountType: a.type,
                            accountCode: a.code,
                            filter: widget.filter,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getAccountTypeColor(int t) {
    switch (t) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.teal;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<_LedgerResult> _load(ReportFilter filter) async {
    final db = await getIt<DatabaseService>().database;
    final args = <Object?>[];
    String df = '';
    if (filter.startDate != null && filter.endDate != null) {
      final dateColumn = normalizedReportTimestampSql('je.entry_date');
      df = 'AND $dateColumn >= ? AND $dateColumn <= ?';
      args.addAll(reportDateRangeArgs(filter));
    }
    final rows = await db.rawQuery('''
      SELECT a.id, a.code, a.name, a.type, 
             COALESCE(SUM(jel.debit_amount), 0) as td, 
             COALESCE(SUM(jel.credit_amount), 0) as tc
      FROM accounts a 
      INNER JOIN journal_entry_lines jel ON jel.account_id = a.id 
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE a.is_active = 1 AND je.is_posted = 1 $df 
      GROUP BY a.id 
      ORDER BY a.code
    ''', args);

    final list = rows.map((m) {
      final code = (m['code'] as String?) ?? '';
      final rawType = (m['type'] as int?) ?? 1;
      final isCreditNormal =
          rawType == 2 ||
          rawType == 4 ||
          code.startsWith('2') ||
          code.startsWith('4');
      final td = (m['td'] as num).toDouble();
      final tc = (m['tc'] as num).toDouble();
      final bal = isCreditNormal ? (tc - td) : (td - tc);

      return _LedgerAccount(
        id: m['id'] as int,
        code: code,
        name: (m['name'] as String?) ?? '',
        type: rawType,
        totalDebit: td,
        totalCredit: tc,
        balance: bal,
      );
    }).toList();

    return _LedgerResult(
      accounts: list,
      totalDebit: list.fold(0, (s, a) => s + a.totalDebit),
      totalCredit: list.fold(0, (s, a) => s + a.totalCredit),
    );
  }
}

class _AccountTransactionsView extends StatefulWidget {
  final int accountId;
  final int accountType;
  final String accountCode;
  final ReportFilter filter;
  const _AccountTransactionsView({
    required this.accountId,
    required this.accountType,
    required this.accountCode,
    required this.filter,
  });

  @override
  State<_AccountTransactionsView> createState() =>
      _AccountTransactionsViewState();
}

class _AccountTransactionsViewState extends State<_AccountTransactionsView> {
  late Future<List<_LedgerTransaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTxns();
  }

  @override
  void didUpdateWidget(covariant _AccountTransactionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId ||
        oldWidget.filter != widget.filter) {
      _future = _loadTxns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LedgerTransaction>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          );
        }
        final txns = snapshot.data!;
        if (txns.isEmpty) {
          return const Padding(
            padding: AppConstant.defaultPadding,
            child: Text(
              'لا توجد حركات تفصيلية في هذه الفترة',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        }
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: txns
                .map(
                  (t) => ListTile(
                    dense: true,
                    title: Text(
                      t.description ?? 'بدون وصف',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      t.dateLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          t.debit > 0
                              ? '+${t.debit.toStringAsFixed(2)} مدين'
                              : '-${t.credit.toStringAsFixed(2)} دائن',
                          style: TextStyle(
                            fontSize: 11,
                            color: t.debit > 0
                                ? Colors.blue[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الرصيد التراكمي: ${t.runningBalance.toStringAsFixed(2)} ر.س',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<List<_LedgerTransaction>> _loadTxns() async {
    final db = await getIt<DatabaseService>().database;
    final isCreditNormal =
        widget.accountType == 2 ||
        widget.accountType == 4 ||
        widget.accountCode.startsWith('2') ||
        widget.accountCode.startsWith('4');

    String df = '';
    final args = <Object?>[widget.accountId];
    if (widget.filter.startDate != null && widget.filter.endDate != null) {
      df = 'AND je.entry_date >= ? AND je.entry_date <= ?';
      args.add(widget.filter.startDate!.millisecondsSinceEpoch ~/ 1000);
      args.add(widget.filter.endDate!.millisecondsSinceEpoch ~/ 1000);
    }

    final rows = await db.rawQuery('''
      SELECT je.entry_date, je.description, jel.debit_amount as d, jel.credit_amount as c 
      FROM journal_entry_lines jel 
      JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = ? AND je.is_posted = 1 $df
      ORDER BY je.entry_date ASC, jel.id ASC
    ''', args);

    double rb = 0;
    return rows.map((m) {
      final d = (m['d'] as num).toDouble();
      final c = (m['c'] as num).toDouble();
      if (isCreditNormal) {
        rb += (c - d);
      } else {
        rb += (d - c);
      }
      return _LedgerTransaction(
        entryDate: m['entry_date'] as int,
        description: m['description'] as String?,
        debit: d,
        credit: c,
        runningBalance: rb,
      );
    }).toList();
  }
}

class _LedgerResult {
  final List<_LedgerAccount> accounts;
  final double totalDebit, totalCredit;
  _LedgerResult({
    required this.accounts,
    required this.totalDebit,
    required this.totalCredit,
  });
}

class _LedgerAccount {
  final int id, type;
  final String code, name;
  final double totalDebit, totalCredit, balance;
  _LedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
  });
}

class _LedgerTransaction {
  final int entryDate;
  final String? description;
  final double debit, credit, runningBalance;
  _LedgerTransaction({
    required this.entryDate,
    this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
  String get dateLabel {
    final d = dateTimeFromReportTimestamp(entryDate);
    return '${d.day}/${d.month}/${d.year}';
  }
}
