import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/services/tafqeet_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VoucherPrintService {
  static Future<void> printVoucher({
    required String number,
    required DateTime date,
    required double amount,
    required bool isReceipt,
    String? accountName,
    String? notes,
  }) async {
    final pdf = await _buildPdf(
      number: number,
      date: date,
      amount: amount,
      isReceipt: isReceipt,
      accountName: accountName,
      notes: notes,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<pw.Document> _buildPdf({
    required String number,
    required DateTime date,
    required double amount,
    required bool isReceipt,
    String? accountName,
    String? notes,
  }) async {
    final fontData = await rootBundle.load(
      'assets/fonts/Tajawal/Tajawal-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData);
    final bottomNotes = SettingsCache.voucherNotesInBottom;

    final logo = _loadImage(SettingsCache.personal['logoPath']?.toString());
    final signature =
        _loadImage(SettingsCache.personal['signature']?.toString());
    final seal = _loadImage(SettingsCache.personal['sealingPath']?.toString());

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat(),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => [
          _buildHeader(ttf, date, number, logo),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              isReceipt ? 'سند قبض' : 'سند صرف',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          _buildWording(ttf, amount, isReceipt, accountName),
          if (SettingsCache.tafqeetAmount) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'المبلغ كتابة: ${TafqeetService.convert(amount)}',
              style: pw.TextStyle(font: ttf, fontSize: 13),
            ),
          ],
          pw.SizedBox(height: 48),
          _buildSignatures(ttf, isReceipt, signature, seal),
          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(notes, style: pw.TextStyle(font: ttf, fontSize: 11)),
          ],
          if (bottomNotes != null && bottomNotes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(bottomNotes, style: pw.TextStyle(font: ttf, fontSize: 11)),
          ],
        ],
      ),
    );
    return pdf;
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

  static PdfPageFormat _pageFormat() {
    final size = SettingsCache.printPaperSize;
    final landscape = SettingsCache.printOrientation == 'landscape';
    if (landscape) {
      return size == 'A5'
          ? PdfPageFormat.a5.landscape
          : PdfPageFormat.a4.landscape;
    }
    return size == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
  }

  static pw.Widget _buildHeader(
    pw.Font ttf,
    DateTime date,
    String number,
    pw.MemoryImage? logo,
  ) {
    final companyName = SettingsCache.personal['name']?.toString() ?? '';
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8),
                child: pw.Image(
                  logo,
                  width: 56,
                  height: 56,
                  fit: pw.BoxFit.contain,
                ),
              ),
            pw.Expanded(
              child: pw.Text(
                companyName,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'التاريخ: ${intl.DateFormat('dd/MM/yyyy').format(date)}',
                  style: pw.TextStyle(font: ttf, fontSize: 11),
                ),
                pw.Text(
                  'رقم السند: $number',
                  style: pw.TextStyle(font: ttf, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildWording(
    pw.Font ttf,
    double amount,
    bool isReceipt,
    String? accountName,
  ) {
    final amountText = intl.NumberFormat('#,##0.00').format(amount);
    final lines = <String>[
      if (isReceipt)
        SettingsCache.receiptVoucherLine1
      else
        SettingsCache.paymentVoucherLine1,
      if (accountName != null && accountName.isNotEmpty) accountName,
      if (isReceipt)
        SettingsCache.receiptVoucherLine2
      else
        SettingsCache.paymentVoucherLine2,
      isReceipt ? 'مبلغ وقدره: $amountText' : amountText,
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              line,
              style: pw.TextStyle(font: ttf, fontSize: 14),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildSignatures(
    pw.Font ttf,
    bool isReceipt,
    pw.MemoryImage? signature,
    pw.MemoryImage? seal,
  ) {
    final mode = SettingsCache.showSignatureAndSealingInVoucher;
    final enabled = isReceipt
        ? SettingsCache.receiptVoucherSignature
        : SettingsCache.paymentVoucherSignature;
    if (!enabled || mode == 0) return pw.SizedBox();
    final labels = isReceipt
        ? SettingsCache.receiptVoucherSignatures
        : SettingsCache.paymentVoucherSignatures;
    return pw.Column(
      children: [
        if (signature != null || seal != null) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (signature != null)
                pw.Image(
                  signature,
                  width: 80,
                  height: 36,
                  fit: pw.BoxFit.contain,
                ),
              if (seal != null) ...[
                if (signature != null) pw.SizedBox(width: 40),
                pw.Image(seal, width: 64, height: 64, fit: pw.BoxFit.contain),
              ],
            ],
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Row(
          children: [
            for (final label in labels.where((l) => l.isNotEmpty))
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                  padding: const pw.EdgeInsets.only(top: 10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  child: pw.Text(
                    label,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
