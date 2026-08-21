import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/features/reports/presentation/widgets/balance_sheet_components.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_base_page.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_kpi_card.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';

import 'package:muhasib/core/constant/app_constant.dart';

class BalanceSheetReportPage extends StatefulWidget {
  const BalanceSheetReportPage({super.key});
  @override
  State<BalanceSheetReportPage> createState() => _BalanceSheetReportPageState();
}

class _BalanceSheetReportPageState extends State<BalanceSheetReportPage> {
  _BalanceSheetResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return ReportBasePage(
      title: 'تقرير الميزانية العمومية',
      icon: Icons.account_balance,
      color: AppColors.materialPurple900,
      onPrint: _lastResult == null ? null : () => _exportPdf(),
      onExportExcel: _lastResult == null ? null : () => _exportExcel(),
      reportBuilder: (filter) => _BalanceSheetContent(
        filter: filter,
        onLoad: (r) => setState(() => _lastResult = r),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_lastResult == null) return;
    final headers = ['البند', 'المبلغ'];
    final List<List<String>> data = [];
    data.add(['الأصول المتداولة', '']);
    for (var r in _lastResult!.currentAssets) {
      data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
    }
    if (_lastResult!.fixedAssets.isNotEmpty) {
      data.add(['الأصول الثابتة', '']);
      for (var r in _lastResult!.fixedAssets) {
        data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
      }
    }
    data.add(['إجمالي الأصول', _lastResult!.totalAssets.toStringAsFixed(2)]);
    data.add(['الخصوم المتداولة', '']);
    for (var r in _lastResult!.currentLiabilities) {
      data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
    }
    if (_lastResult!.longTermLiabilities.isNotEmpty) {
      data.add(['الخصوم طويلة الأجل', '']);
      for (var r in _lastResult!.longTermLiabilities) {
        data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
      }
    }
    data.add(['حقوق الملكية', '']);
    for (var r in _lastResult!.equityRows) {
      data.add(['  ${r.code} - ${r.name}', r.displayAmount.toStringAsFixed(2)]);
    }
    data.add([
      'الإجمالي خصوم + ملكية',
      (_lastResult!.totalLiabilities + _lastResult!.totalEquity)
          .toStringAsFixed(2),
    ]);
    data.add([
      'الفرق (أصول - خصوم/ملكية)',
      _lastResult!.difference.toStringAsFixed(2),
    ]);

    await ExportService.printData(
      title: 'الميزانية العمومية',
      headers: headers,
      data: data,
    );
  }

  Future<void> _exportExcel() async {
    if (_lastResult == null) return;
    final rows = [
      ..._lastResult!.currentAssets,
      ..._lastResult!.fixedAssets,
      ..._lastResult!.currentLiabilities,
      ..._lastResult!.longTermLiabilities,
      ..._lastResult!.equityRows,
    ];
    final path = await ExportService.exportToExcel(
      fileName: 'balance_sheet',
      headers: ['كود الحساب', 'الاسم', 'المبلغ'],
      data: rows
          .map((r) => [r.code, r.name, r.displayAmount.toStringAsFixed(2)])
          .toList(),
    );
    AppToast.showSuccess(context, 'تم تصدير Excel: $path');
  }
}

class _BalanceSheetContent extends StatefulWidget {
  final ReportFilter filter;
  final Function(_BalanceSheetResult) onLoad;

  const _BalanceSheetContent({required this.filter, required this.onLoad});

  @override
  State<_BalanceSheetContent> createState() => _BalanceSheetContentState();
}

class _BalanceSheetContentState extends State<_BalanceSheetContent> {
  late Future<_BalanceSheetResult> _future;
  _BalanceSheetResult? _notifiedResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant _BalanceSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _fetchData();
    }
  }

  void _fetchData() {
    _notifiedResult = null;
    _future = _load(widget.filter);
  }

  String _format(double v) => NumberFormatter.formatCurrency(v, symbol: 'ر.س');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BalanceSheetResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('خطأ: ${snapshot.error}'));
        final data = snapshot.data;
        if (data != null && data != _notifiedResult) {
          _notifiedResult = data;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoad(data),
          );
        }
        if (data == null) return const Center(child: Text('لا توجد بيانات'));

        final workingCapital = data.totalAssets - data.totalLiabilities;

        var assets = data.currentAssets;
        var liabilitiesAndEquity = [
          ...data.currentLiabilities,
          ...data.equityRows,
        ];

        if (widget.filter.searchQuery != null &&
            widget.filter.searchQuery!.isNotEmpty) {
          final query = widget.filter.searchQuery!.toLowerCase();
          assets = assets
              .where(
                (r) =>
                    r.code.toLowerCase().contains(query) ||
                    r.name.toLowerCase().contains(query),
              )
              .toList();
          liabilitiesAndEquity = liabilitiesAndEquity
              .where(
                (r) =>
                    r.code.toLowerCase().contains(query) ||
                    r.name.toLowerCase().contains(query),
              )
              .toList();
        }

        return SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            children: [
              BalanceSheetEquationWidget(result: data),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'إجمالي الأصول',
                        value: _format(data.totalAssets),
                        icon: Icons.trending_up,
                        color: Colors.green[700]!,
                        subtitle: 'الأصول المتداولة والثابتة',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'الخصوم وحقوق الملكية',
                        value: _format(data.totalLiabilities + data.totalEquity),
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue[700]!,
                        subtitle: 'التزامات + الملكية',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: ReportKpiCard(
                        title: 'رأس المال العامل',
                        value: _format(workingCapital),
                        icon: Icons.account_balance,
                        color: workingCapital >= 0
                            ? Colors.teal[700]!
                            : Colors.red[700]!,
                        subtitle: 'الأصول - الخصوم',
                        isPositiveTrend: workingCapital >= 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              BalanceSheetSectionWidget(
                title: 'الأصول',
                value: data.totalAssets,
                color: Colors.green[800]!,
                icon: Icons.trending_up,
                rows: assets,
                formatCurrency: _format,
              ),
              const SizedBox(height: 16),
              BalanceSheetSectionWidget(
                title: 'الخصوم وحقوق الملكية',
                value: data.totalLiabilities + data.totalEquity,
                color: Colors.blue[800]!,
                icon: Icons.account_balance_wallet,
                rows: liabilitiesAndEquity,
                formatCurrency: _format,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_BalanceSheetResult> _load(ReportFilter f) async {
    final ds = getIt<ReportsLocalDataSource>();
    final asOf = (f.endDate ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    final accounts = await ds.getBalanceSheetAccounts(asOfSeconds: asOf);

    final niRes = await ds.getBalanceSheetNetIncome(asOfSeconds: asOf);
    final ni = (niRes.first['ni'] as num).toDouble();

    return computeBalanceSheet(accounts, ni);
  }
}

/// تصنيف وتجميع الميزانية العمومية بشكل نقي وقابل للاختبار.
/// AccountType: 0=assets, 1=liabilities, 2=equity.
// ignore: library_private_types_in_public_api
_BalanceSheetResult computeBalanceSheet(
  List<Map<String, dynamic>> accounts,
  double netIncome,
) {
  final curA = <_AccountBalanceRow>[],
      fixA = <_AccountBalanceRow>[],
      othA = <_AccountBalanceRow>[],
      curL = <_AccountBalanceRow>[],
      ltrL = <_AccountBalanceRow>[],
      equ = <_AccountBalanceRow>[];
  double tA = 0, tL = 0, tE = 0;

  for (final m in accounts) {
    final code = (m['code'] as String?) ?? '';
    final name = (m['name'] as String?) ?? '';
    final rawType = m['type'] as int? ?? 0;
    final lowerName = name.toLowerCase();

    final isAsset = rawType == 0 || code.startsWith('1');
    final isEquity = (rawType == 2 || code.startsWith('2')) &&
        (code.startsWith('22') ||
            code.startsWith('23') ||
            code.startsWith('24') ||
            name.contains('رأس المال') ||
            lowerName.contains('capital') ||
            lowerName.contains('equity') ||
            name.contains('أرباح') ||
            lowerName.contains('retained') ||
            name.contains('ملكية') ||
            name.contains('جاري المالك') ||
            name.contains('حقوق'));

    final r = _AccountBalanceRow(
      id: m['id'] as int,
      code: code,
      name: name,
      type: isAsset ? 0 : (isEquity ? 2 : 1),
      net: (m['net'] as num).toDouble(),
    );

    if (isAsset) {
      if (code.startsWith('12') || code.startsWith('13') || name.contains('ثابت')) {
        fixA.add(r);
      } else {
        curA.add(r);
      }
      tA += r.displayAmount;
    } else if (isEquity) {
      equ.add(r);
      tE += r.displayAmount;
    } else {
      if (code.startsWith('23') || name.contains('طويلة الأجل')) {
        ltrL.add(r);
      } else {
        curL.add(r);
      }
      tL += r.displayAmount;
    }
  }

  if (netIncome.abs() > 0.01) {
    equ.add(
      _AccountBalanceRow(
        id: -1,
        code: 'NI',
        name: 'صافي دخل الفترة التراكمي',
        type: 2,
        net: -netIncome,
      ),
    );
    tE += netIncome;
  }

  return _BalanceSheetResult(
    currentAssets: curA,
    fixedAssets: fixA,
    otherAssets: othA,
    currentLiabilities: curL,
    longTermLiabilities: ltrL,
    equityRows: equ,
    totalAssets: tA,
    totalLiabilities: tL,
    totalEquity: tE,
    netIncome: netIncome,
  );
}

class _BalanceSheetResult {
  final List<_AccountBalanceRow> currentAssets,
      fixedAssets,
      otherAssets,
      currentLiabilities,
      longTermLiabilities,
      equityRows;
  final double totalAssets, totalLiabilities, totalEquity, netIncome;
  _BalanceSheetResult({
    required this.currentAssets,
    required this.fixedAssets,
    required this.otherAssets,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.equityRows,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.netIncome,
  });
  double get difference => totalAssets - (totalLiabilities + totalEquity);
  bool get isBalanced => difference.abs() < 0.01;
}

class _AccountBalanceRow {
  final int id;
  final String code, name;
  final int type;
  final double net;
  _AccountBalanceRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.net,
  });
  double get displayAmount => (type == 1 || type == 2) ? -net : net;
}
