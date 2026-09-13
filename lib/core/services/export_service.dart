import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/services/settings_cache.dart';

class ExportService {
  /// تصدير البيانات إلى PDF والطباعة المباشرة
  static Future<void> printData({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    Map<String, String>? settings,
    bool showInvoiceTerms = false,
  }) async {
    final pdf = await _generatePdf(
      title,
      headers,
      data,
      settings,
      showInvoiceTerms: showInvoiceTerms,
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// مشاركة المستند كملف PDF (شاشة المشاركة على الجوال).
  static Future<void> sharePdf({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    Map<String, String>? settings,
    bool showInvoiceTerms = false,
  }) async {
    final pdf = await _generatePdf(
      title,
      headers,
      data,
      settings,
      showInvoiceTerms: showInvoiceTerms,
    );
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf',
    );
  }

  /// تصدير البيانات إلى ملف Excel
  static Future<String> exportToExcel({
    required String fileName,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // إضافة الترويسة
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#EEEEEE'),
      );
    }

    // إضافة البيانات
    for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
      for (var colIdx = 0; colIdx < data[rowIdx].length; colIdx++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1));
        cell.value = TextCellValue(data[rowIdx][colIdx]);
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/$fileName.xlsx";
    final file = File(path);
    await file.writeAsBytes(excel.save()!);
    return path;
  }

  /// إنشاء مستند PDF يدعم العربية
  static Future<pw.Document> _generatePdf(
    String title,
    List<String> headers,
    List<List<String>> data,
    Map<String, String>? settings, {
    bool showInvoiceTerms = false,
  }) async {
    final pdf = pw.Document();

    // تحميل الخط العربي لضمان ظهور النصوص العربية بشكل صحيح
    // ملاحظة: تأكد من وجود الخط في مسار assets/fonts/Tajawal/Tajawal-Regular.ttf
    final fontData = await rootBundle.load("assets/fonts/Tajawal/Tajawal-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final repeatHeader = SettingsCache.repeatPrintHeaderInAllPages;
    final headerWidget = _buildHeader(
      title,
      settings,
      ttf,
      _loadImage(SettingsCache.personal['logoPath']?.toString()),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat(),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        header: repeatHeader
            ? (context) => pw.Column(children: [headerWidget, pw.SizedBox(height: 10)])
            : null,
        build: (context) => [
          if (!repeatHeader) headerWidget,
          pw.SizedBox(height: 10),
          _buildTable(headers, data, ttf),
          pw.SizedBox(height: 10),
          _buildFooter(settings, ttf, showInvoiceTerms: showInvoiceTerms),
        ],
      ),
    );

    return pdf;
  }

  static PdfPageFormat _pageFormat() {
    final size = SettingsCache.printPaperSize;
    final landscape = SettingsCache.printOrientation == 'landscape';
    if (landscape) {
      return size == 'A5' ? PdfPageFormat.a5.landscape : PdfPageFormat.a4.landscape;
    }
    return size == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
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

  static pw.Widget _buildHeader(
    String title,
    Map<String, String>? settings,
    pw.Font font, [
    pw.MemoryImage? logo,
  ]) {
    final personal = SettingsCache.personal;
    final companyName = settings?['company_name'] ??
        (SettingsCache.showPrintCompanyName
            ? personal['name']?.toString()
            : null) ??
        'نظام محاسب الرقمي';

    final infoLines = <String>[
      if (SettingsCache.showPrintHeaderData &&
          SettingsCache.showPrintCompanyAddress &&
          (personal['address']?.toString() ?? '').isNotEmpty)
        personal['address'].toString(),
      if (SettingsCache.showPrintHeaderData &&
          SettingsCache.showPrintCompanyPhone &&
          (personal['phone']?.toString() ?? '').isNotEmpty)
        'هاتف: ${personal['phone']}',
    ];

    String dateStr = '';
    if (SettingsCache.showPrintHeaderData &&
        (SettingsCache.showPrintDate || SettingsCache.showPrintTime)) {
      final datePart = intl.DateFormat('yyyy/MM/dd').format(DateTime.now());
      final timePart = intl.DateFormat('HH:mm').format(DateTime.now());
      if (SettingsCache.showPrintDate && SettingsCache.showPrintTime) {
        dateStr = '$datePart $timePart';
      } else if (SettingsCache.showPrintDate) {
        dateStr = datePart;
      } else {
        dateStr = timePart;
      }
    }

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
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(companyName, style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  for (final line in infoLines)
                    pw.Text(line, style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ),
            ),
            if (dateStr.isNotEmpty)
              pw.Text('تاريخ التقرير: $dateStr', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> data, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: pw.TextStyle(font: font, fontSize: 8),
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.centerRight,
    );
  }

  static pw.Widget _buildFooter(
    Map<String, String>? settings,
    pw.Font font, {
    bool showInvoiceTerms = false,
  }) {
    final terms = showInvoiceTerms ? SettingsCache.invoiceTerms.trim() : '';
    final footer = showInvoiceTerms ? SettingsCache.invoiceFooter.trim() : '';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (terms.isNotEmpty || footer.isNotEmpty) ...[
          pw.Divider(),
          if (terms.isNotEmpty)
            pw.Text('الشروط: $terms', style: pw.TextStyle(font: font, fontSize: 8)),
          if (footer.isNotEmpty)
            pw.Text(footer, style: pw.TextStyle(font: font, fontSize: 8)),
        ],
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('طُبع بواسطة نظام محاسب', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
            pw.Text('مركز تقنية المعلومات', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }
}
