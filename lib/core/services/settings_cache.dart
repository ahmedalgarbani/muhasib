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

  static Map<String, dynamic> get security => _section('security_info');

  static Map<String, dynamic> get backup => _section('backup_settings');

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

  static int get decimalNoInput => _get(other, 'decimalNoInput', 7) as int;

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

  static bool get showTaxModule =>
      _get(other, 'showTaxModule', true) as bool;

  static bool get showAccountantAdvanceModule =>
      _get(other, 'showAccountantAdvanceModule', true) as bool;

  static String get timezone => _get(other, 'timezone', '') as String;

  static bool get useMiniHasib =>
      _get(other, 'useMiniHasib', false) as bool;

  static String get language => _get(other, 'language', 'ar') as String;

  static int get homeScrrenType =>
      _get(other, 'homeScrrenType', 1) as int;

  static bool get showBackupNotifyWhenCloseApp =>
      _get(other, 'showBackupNotifyWhenCloseApp', true) as bool;

  // default currency (code resolved against the currencies table at startup)
  static String _defaultCurrencyCode = 'SAR';

  static String _defaultCurrencySymbol = 'ريال';

  static String get defaultCurrencyCode => _defaultCurrencyCode;

  static String get defaultCurrencySymbol => _defaultCurrencySymbol;

  static void setDefaultCurrency({required String code, String? symbol}) {
    _defaultCurrencyCode = code;
    _defaultCurrencySymbol =
        (symbol == null || symbol.trim().isEmpty) ? code : symbol;
  }

  // security_info
  static bool get securityIsActive =>
      _get(security, 'isActive', false) as bool;

  static String? get securityPassword {
    final value = _get(security, 'password', null);
    return value == null ? null : value.toString();
  }

  // backup_settings
  static int get backupDeviceSaveMethod =>
      _get(backup, 'deviceSaveMethod', 1) as int;

  static int get backupDriveSaveMethod =>
      _get(backup, 'driveSaveMethod', 0) as int;

  static int get backupHours => _get(backup, 'hours', 24) as int;

  static int get backupDriveHours => _get(backup, 'driveHours', 24) as int;

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

  static bool get checkFundAndBankBalanceInInvoice =>
      _get(stock, 'checkFundAndBankBalanceEnabledInInvoice', false) as bool;

  // voucher_setting
  static bool get allowMultiCurrencyInVoucher =>
      _get(voucher, 'allowMultiCurrencyInVoucher', false) as bool;

  static int get paymentDueDays =>
      _get(voucher, 'payment_due_days', 30) as int;

  static String get paymentVoucherLine1 =>
      _get(voucher, 'paymentVoucherLine1', 'الاخ') as String;

  static String get paymentVoucherLine2 =>
      _get(voucher, 'paymentVoucherLine2', 'عليكم مبلغ') as String;

  static String get receiptVoucherLine1 =>
      _get(voucher, 'receiptVoucherVoucherLine1', 'الاخ') as String;

  static String get receiptVoucherLine2 =>
      _get(voucher, 'receiptVoucherVoucherLine2', 'لكم مبلغ') as String;

  static bool get paymentVoucherSignature =>
      _get(voucher, 'paymentVoucherSignature', true) as bool;

  static bool get receiptVoucherSignature =>
      _get(voucher, 'receiptVoucherSignature', true) as bool;

  static List<String> get paymentVoucherSignatures => [
        _get(voucher, 'paymentVoucherFirstSignature', 'المستلم') as String,
        _get(voucher, 'paymentVoucherSecondSignature', 'مدير الحسابات') as String,
        _get(voucher, 'paymentVoucherThirdSignature', 'الصندوق') as String,
        _get(voucher, 'paymentVoucherFourthSignature', 'المدير العام') as String,
      ];

  static List<String> get receiptVoucherSignatures => [
        _get(voucher, 'receiptVoucherFirstSignature', 'المستلم') as String,
        _get(voucher, 'receiptVoucherSecondSignature', 'مدير الحسابات') as String,
        _get(voucher, 'receiptVoucherThirdSignature', 'الصندوق') as String,
        _get(voucher, 'receiptVoucherFourthSignature', 'المدير العام') as String,
      ];

  static String? get voucherNotesInBottom {
    final value = _get(voucher, 'notesInBotton', null);
    return value == null ? null : value.toString();
  }

  static bool get showAccountBalanceInVoucher =>
      _get(voucher, 'showAccountBalanceInVoucher', false) as bool;

  static bool get checkFundAndBankBalanceInVoucher =>
      _get(voucher, 'checkFundAndBankBalanceEnabledInVoucher', false) as bool;

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

  static bool get tafqeetAmount =>
      _get(printer, 'tafqeetAmount', false) as bool;

  // pos_setting
  static String get defaultPaymentMethod =>
      _get(pos, 'default_payment_method', 'cash') as String;

  static double? get maxDiscountPercent {
    final value = _get(pos, 'max_discount_percent', null);
    return value == null ? null : (value as num).toDouble();
  }

  static String get posDefaultCustomer =>
      _get(pos, 'default_customer', '') as String;

  static bool get posPrintReceiptAutomatically =>
      _get(pos, 'print_receipt_automatically', true) as bool;

  static int get posReceiptPrinterWidth =>
      _get(pos, 'receipt_printer_width', 80) as int;

  static int get posReceiptCopies => _get(pos, 'receipt_copies', 1) as int;

  static bool get posAllowDiscountPerLine =>
      _get(pos, 'allow_discount_per_line', true) as bool;

  static bool get posCashRoundingEnabled =>
      _get(pos, 'cash_rounding_enabled', false) as bool;

  static double get posCashRoundingPrecision =>
      (_get(pos, 'cash_rounding_precision', 0.05) as num).toDouble();

  static bool get posBarcodeEnabled =>
      _get(pos, 'barcode_enabled', true) as bool;

  static bool get posShowBarcodeScanner =>
      _get(pos, 'show_barcode_scanner', false) as bool;

  static bool get posEnableStockAlerts =>
      _get(pos, 'enable_stock_alerts', true) as bool;

  static bool get posEnableCustomerCredit =>
      _get(pos, 'enable_customer_credit', false) as bool;

  static double get posDefaultCreditLimit =>
      (_get(pos, 'default_credit_limit', 0) as num).toDouble();

  static bool get posBlockCustomerOverLimit =>
      _get(pos, 'block_customer_over_limit', false) as bool;

  static bool get posAllowHoldOrders =>
      _get(pos, 'allow_hold_orders', true) as bool;

  static bool get posAllowSplitPayment =>
      _get(pos, 'allow_split_payment', true) as bool;

  static bool get posShowRemainingBalanceInReceipt =>
      _get(pos, 'show_remaining_balance_in_receipt', true) as bool;
}
