import 'dart:convert';

/// In-memory snapshot of app settings, refreshed by [SettingsCubit].
/// Lets non-UI helpers (formatters, export, numbering) read settings
/// without a BuildContext.
class SettingsCache {
  static Map<String, dynamic> _all = {};

  static void update(Map<String, dynamic> allSettings) {
    _all = allSettings;
  }

  static Map<String, dynamic> _section(String key) {
    final value = _all[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static Map<String, dynamic> get other => _section('other_setting');

  static Map<String, dynamic> get stock => _section('stock_setting');

  static Map<String, dynamic> get voucher => _section('voucher_setting');

  static Map<String, dynamic> get printer => _section('printer_info');

  static Map<String, dynamic> get personal => _section('personal_info');

  static Map<String, dynamic> get pos => _section('pos_setting');

  static dynamic _get(
    Map<String, dynamic> section,
    String key,
    dynamic fallback,
  ) {
    return section.containsKey(key) && section[key] != null
        ? section[key]
        : fallback;
  }

  // other_setting
  static int get dateFormat => _get(other, 'dateFormat', 0) as int;

  static int get timeFormat => _get(other, 'timeFormat', 0) as int;

  static int get decimalNoOutput => _get(other, 'decimalNoOutput', 2) as int;

  static String get thousandsSeparator =>
      _get(other, 'thousands_separator', ',') as String;

  static String get decimalSeparator =>
      _get(other, 'decimal_separator', '.') as String;

  static String get debitLabel => _get(other, 'debit', 'مدين') as String;

  static String get creditLabel => _get(other, 'credit', 'دائن') as String;

  static double get fontScale => (_get(other, 'fontScale', 1) as num).toDouble();

  static bool get showStockModule =>
      _get(other, 'showStockModule', true) as bool;

  // stock_setting
  static String get invoicePrefix =>
      _get(stock, 'invoice_prefix', 'INV-') as String;

  static int get invoiceStartingNumber =>
      _get(stock, 'invoice_starting_number', 1000) as int;

  static String get quotationPrefix =>
      _get(stock, 'quotation_prefix', 'QUO-') as String;

  static String get returnPrefix =>
      _get(stock, 'return_prefix', 'RET-') as String;

  static bool get taxEnabled => _get(stock, 'tax_enabled', false) as bool;

  static double get defaultTaxRate =>
      (_get(stock, 'default_tax_rate', 15) as num).toDouble();

  static String get taxName =>
      _get(stock, 'tax_name', 'ضريبة القيمة المضافة') as String;

  static bool get taxInclusivePricing =>
      _get(stock, 'tax_inclusive_pricing', false) as bool;

  static int get defaultWarehouse =>
      _get(stock, 'default_warehouse', 1) as int;

  static bool get preventSaleLessThanCost =>
      _get(stock, 'preventWhenSaleLessThanCost', true) as bool;

  static bool get allowNegativeStock =>
      _get(stock, 'isStockNegativeAllowed', false) as bool;

  static bool get showCostInInvoice =>
      _get(stock, 'showCoseAmountInInvoice', true) as bool;

  static bool get showCustomerBalanceInInvoice =>
      _get(stock, 'showCustomerBalanceInInvoice', false) as bool;

  static bool get showCustomerPhoneInInvoice =>
      _get(stock, 'showCustomPhoneInInvoice', true) as bool;

  static bool get showCostWhenAddInvoice =>
      _get(stock, 'showCostAmountInCategoryWhenAddInvoice', true) as bool;

  static bool get allowReturnWithoutInvoice =>
      _get(stock, 'allowReturnWithoutInvoice', true) as bool;

  static String get invoiceTerms =>
      _get(stock, 'invoice_terms', '') as String;

  static String get invoiceFooter =>
      _get(stock, 'invoice_footer', '') as String;

  // voucher_setting
  static bool get allowMultiCurrencyInVoucher =>
      _get(voucher, 'allowMultiCurrencyInVoucher', false) as bool;

  static int get paymentDueDays =>
      _get(voucher, 'payment_due_days', 30) as int;

  // printer_info
  static bool get showPrintDate => _get(printer, 'showDate', false) as bool;

  static bool get showPrintTime => _get(printer, 'showTime', false) as bool;

  static bool get showPrintCompanyName =>
      _get(printer, 'showHeaderCompanyName', true) as bool;

  static bool get showPrintCompanyAddress =>
      _get(printer, 'showHeaderCompanyAddress', true) as bool;

  static bool get showPrintCompanyPhone =>
      _get(printer, 'showHeaderCompanyPhone', true) as bool;

  static String get printPaperSize =>
      _get(printer, 'print_paper_size', 'A4') as String;

  static String get printOrientation =>
      _get(printer, 'print_orientation', 'portrait') as String;

  // pos_setting
  static String get defaultPaymentMethod =>
      _get(pos, 'default_payment_method', 'cash') as String;

  static double? get maxDiscountPercent {
    final value = _get(pos, 'max_discount_percent', null);
    return value == null ? null : (value as num).toDouble();
  }
}
