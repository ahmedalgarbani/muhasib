import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PosReceiptLine {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const PosReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class PosReceiptPrintService {
  static Future<void> printReceipt({
    required String number,
    required DateTime date,
    required List<PosReceiptLine> lines,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
    required double change,
    required double remaining,
    String? customerName,
    double? customerBalance,
  }) async {
    final pdf = await _buildPdf(
      number: number,
      date: date,
      lines: lines,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      paid: paid,
      change: change,
      remaining: remaining,
      customerName: customerName,
      customerBalance: customerBalance,
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.MemoryImage? _loadImage(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Document> _buildPdf({
    required String number,
    required DateTime date,
    required List<PosReceiptLine> lines,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
    required double change,
    required double remaining,
    String? customerName,
    double? customerBalance,
  }) async {
    final fontData = await rootBundle.load(
      'assets/fonts/Tajawal/Tajawal-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    final widthMm = SettingsCache.posReceiptPrinterWidth <= 58 ? 58.0 : 80.0;
    final copies = math.max(1, SettingsCache.posReceiptCopies);
    final showRemaining = SettingsCache.posShowRemainingBalanceInReceipt;
    final logo = _loadImage(SettingsCache.personal['logoPath']?.toString());
    final companyName = SettingsCache.personal['name']?.toString() ?? '';

    final contentHeight =
        55.0 + lines.length * 5.5 + (showRemaining ? 20.0 : 10.0);
    final heightMm = math.max(100.0, contentHeight);

    final pageFormat = PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      heightMm * PdfPageFormat.mm,
    );

    final pdf = pw.Document();
    for (var copy = 0; copy < copies; copy++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: ttf),
          margin: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null)
                pw.Center(
                  child: pw.Image(
                    logo,
                    width: 40 * PdfPageFormat.mm,
                    height: 20 * PdfPageFormat.mm,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (companyName.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'فاتورة مبيعات',
                  style: pw.TextStyle(font: ttf, fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.6, borderStyle: pw.BorderStyle.dashed),
              _row(ttf, 'رقم الفاتورة', number),
              _row(ttf, 'التاريخ', _dateTime(date)),
              if (customerName != null && customerName.isNotEmpty)
                _row(ttf, 'العميل', customerName),
              pw.Divider(thickness: 0.6, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),
              for (final line in lines) ...[
                pw.Text(
                  line.name,
                  style: pw.TextStyle(font: ttf, fontSize: 9.5),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${_num(line.quantity)} × ${_num(line.unitPrice)}',
                      style: pw.TextStyle(font: ttf, fontSize: 9),
                    ),
                    pw.Text(
                      _num(line.total),
                      style: pw.TextStyle(font: ttf, fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],
              pw.Divider(thickness: 0.6, borderStyle: pw.BorderStyle.dashed),
              _row(ttf, 'الإجمالي قبل الخصم', _num(subtotal)),
              if (discount > 0) _row(ttf, 'الخصم', _num(discount)),
              if (tax > 0) _row(ttf, 'الضريبة', _num(tax)),
              _row(ttf, 'الإجمالي', _num(total), bold: true),
              if (paid > 0) _row(ttf, 'المدفوع', _num(paid)),
              if (change > 0) _row(ttf, 'الفكة', _num(change)),
              if (showRemaining && remaining > 0)
                _row(ttf, 'المتبقي', _num(remaining), bold: true),
              if (showRemaining &&
                  customerBalance != null &&
                  customerBalance.abs() > 0.001)
                _row(ttf, 'رصيد العميل', _num(customerBalance)),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'شكراً لتعاملكم معنا',
                  style: pw.TextStyle(font: ttf, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return pdf;
  }

  static pw.Widget _row(
    pw.Font ttf,
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 9.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 9.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double value) => NumberFormatter.formatNumber(value);

  static String _dateTime(DateTime date) {
    return intl.DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
