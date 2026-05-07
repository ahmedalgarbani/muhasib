import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;

class ExportService {
  /// تصدير البيانات إلى PDF والطباعة المباشرة
  static Future<void> printData({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    Map<String, String>? settings,
  }) async {
    final pdf = await _generatePdf(title, headers, data, settings);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
    Map<String, String>? settings,
  ) async {
    final pdf = pw.Document();
    
    // تحميل الخط العربي لضمان ظهور النصوص العربية بشكل صحيح
    // ملاحظة: تأكد من وجود الخط في مسار assets/fonts/Tajawal-Regular.ttf
    final fontData = await rootBundle.load("assets/fonts/Tajawal/Tajawal-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => [
          _buildHeader(title, settings, ttf),
          pw.SizedBox(height: 20),
          _buildTable(headers, data, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(settings, ttf),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String title, Map<String, String>? settings, pw.Font font) {
    final companyName = settings?['company_name'] ?? 'نظام محاسب الرقمي';
    final dateStr = intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(companyName, style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _buildFooter(Map<String, String>? settings, pw.Font font) {
    return pw.Column(
      children: [
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
