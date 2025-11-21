import 'package:flutter/material.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';
import 'package:intl/intl.dart';

class AccountMovementsDialog extends StatelessWidget {
  final AccountModel account;

  const AccountMovementsDialog({Key? key, required this.account})
    : super(key: key);

  String formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'ar_SA');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    final textScale = MediaQuery.of(context).textScaleFactor;

    double baseFont = isTablet ? 16 : 12;
    double padding = isTablet ? 20 : 12;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 100 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                /// ------------------- HEADER -------------------
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: EdgeInsets.all(padding * 1.5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حركات الحساب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: baseFont * 1.6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${account.name} - ${account.code}',
                              style: TextStyle(
                                color: const Color(0xFFBFDBFE),
                                fontSize: baseFont * 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        iconSize: isTablet ? 28 : 24,
                      ),
                    ],
                  ),
                ),

                /// ------------------- BODY -------------------
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(padding * 1.5),
                    child: Column(
                      children: [
                        /// --------- STAT CARDS (responsive row/column) ----------
                        LayoutBuilder(
                          builder: (context, c) {
                            bool isNarrow = c.maxWidth < 600;
                            return isNarrow
                                ? Column(
                                    spacing: 10,
                                    children: [
                                      _StatCard(
                                        title: 'إجمالي المدين',
                                        value: formatNumber(account.balance),
                                        color: Colors.green,
                                        fontSize: baseFont,
                                      ),
                                      _StatCard(
                                        title: 'إجمالي الدائن',
                                        value: '0',
                                        color: Colors.red,
                                        fontSize: baseFont,
                                      ),
                                      _StatCard(
                                        title: 'الرصيد',
                                        value: formatNumber(account.balance),
                                        color: Colors.blue,
                                        fontSize: baseFont,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          title: 'إجمالي المدين',
                                          value: formatNumber(account.balance),
                                          color: Colors.green,
                                          fontSize: baseFont,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _StatCard(
                                          title: 'إجمالي الدائن',
                                          value: '0',
                                          color: Colors.red,
                                          fontSize: baseFont,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _StatCard(
                                          title: 'الرصيد',
                                          value: formatNumber(account.balance),
                                          color: Colors.blue,
                                          fontSize: baseFont,
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),

                        SizedBox(height: padding * 1.5),

                        /// ---------------- TABLE ----------------
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 600,
                              ), // allow scrolling on small screens
                              child: Table(
                                border: TableBorder.all(
                                  color: Colors.grey[200]!,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.2),
                                  1: FlexColumnWidth(2.2),
                                  2: FlexColumnWidth(1.2),
                                  3: FlexColumnWidth(1.2),
                                  4: FlexColumnWidth(1.2),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    children: const [
                                      _TableHeader('التاريخ'),
                                      _TableHeader('البيان'),
                                      _TableHeader('مدين'),
                                      _TableHeader('دائن'),
                                      _TableHeader('الرصيد'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _TableCell('2025-01-15'),
                                      _TableCell('رصيد افتتاحي'),
                                      _TableCell(
                                        formatNumber(account.balance),
                                        color: Colors.green,
                                      ),
                                      _TableCell('-', color: Colors.grey),
                                      _TableCell(
                                        formatNumber(account.balance),
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: padding * 2),

                        Text(
                          'لا توجد حركات إضافية',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: baseFont * 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ------------------- STAT CARD -------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final double fontSize;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(fontSize * 1.2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey, fontSize: fontSize),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: fontSize * 1.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------- TABLE HEADER -------------------
class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// ------------------- TABLE CELL -------------------
class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _TableCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: color ?? Colors.black87,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
