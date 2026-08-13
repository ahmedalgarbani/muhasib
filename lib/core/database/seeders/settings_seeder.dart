import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class SettingsSeeder {
  /// Single source of truth for all default settings.
  /// Used by [seed] (fresh DB, replace) and by
  /// SettingsRepository.initializeDefaultSettings (ignore if exists).
  static List<Map<String, dynamic>> get defaultSettings {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Map<String, dynamic> setting(
      String key,
      String value, {
      String type = 'STRING',
      String category = 'General',
      String? description,
    }) {
      return {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': key,
        'setting_value': value,
        'setting_type': type,
        'category': category,
        if (description != null) 'description': description,
      };
    }

    return [
      // personal_info - معلومات الشركة
      setting('personal_info', json.encode({
        'name': 'اسم الشركة',
        'address': 'عنوان الشركة',
        'logoPath': null,
        'signature': null,
        'nameFrn': 'Company Name',
        'AddressFrn': 'Company Address',
        'taxNo': null,
        'phone': '0500000000',
        'phoneFrn': '0500000000',
        'sealingPath': null,
        'company_email': 'info@company.com',
        'company_commercial_register': '',
        'fiscal_year_start': '01-01',
        'fiscal_year_end': '12-31',
      })),
      setting(
        'initial_setup_done',
        'false',
        type: 'BOOLEAN',
        description: 'Flag indicating whether the onboarding wizard was completed',
      ),

      // security_info - إعدادات الأمان
      setting('security_info', json.encode({
        'isActive': false,
        'password': null,
        'backup_enabled': true,
        'backup_frequency': 'daily',
        'initial_setup_done': false,
      })),

      // printer_info - إعدادات الطباعة
      setting('printer_info', json.encode({
        'printType': 1,
        'printSize': 0,
        'printerConnect': 1,
        'showHeaderData': true,
        'repateHeaderInAllPages': true,
        'showDate': false,
        'showTime': false,
        'showSignatureAndSealingInVoucher': 2,
        'showSignatureAndSealingInInvoice': 2,
        'showSignatureAndSealingInJournal': 2,
        'tafqeetAmount': false,
        'showHeaderCompanyName': true,
        'showHeaderCompanyAddress': true,
        'showHeaderCompanyPhone': true,
        'printFontType': 'assets/fonts/Alexandria-Regular.ttf',
        'print_paper_size': 'A4',
        'print_orientation': 'portrait',
        'print_copies': 1,
        'show_print_preview': true,
      })),

      // other_setting - إعدادات النظام العامة
      setting('other_setting', json.encode({
        'dateFormat': 0,
        'timeFormat': 0,
        'decimalNoInput': 7,
        'decimalNoOutput': 2,
        'debit': 'مدين',
        'credit': 'دائن',
        'showStockModule': true,
        'showAccountantAdvanceModule': true,
        'updateCostAmountType': 2,
        'showTaxModule': false,
        'homeScrrenType': 1,
        'useMiniHasib': false,
        'showBackupNotifyWhenCloseApp': true,
        'fontScale': 1,
        'language': 'ar',
        'timezone': 'Asia/Riyadh',
        'default_currency': 'SAR',
        'decimal_places': 2,
        'thousands_separator': ',',
        'decimal_separator': '.',
      })),

      // voucher_setting - إعدادات السندات
      setting('voucher_setting', json.encode({
        'paymentVoucherLine1': 'الاخ',
        'paymentVoucherLine2': 'عليكم مبلغ',
        'receiptVoucherVoucherLine1': 'الاخ',
        'receiptVoucherVoucherLine2': 'لكم مبلغ',
        'paymentVoucherSignature': true,
        'paymentVoucherFirstSignature': 'المستلم',
        'paymentVoucherSecondSignature': 'مدير الحسابات',
        'paymentVoucherThirdSignature': 'الصندوق',
        'paymentVoucherFourthSignature': 'المدير العام',
        'receiptVoucherSignature': true,
        'receiptVoucherFirstSignature': 'المستلم',
        'receiptVoucherSecondSignature': 'مدير الحسابات',
        'receiptVoucherThirdSignature': 'الصندوق',
        'receiptVoucherFourthSignature': 'المدير العام',
        'notesInBotton': null,
        'allowMultiCurrencyInVoucher': false,
        'showAccountBalanceInVoucher': false,
        'checkFundAndBankBalanceEnabledInVoucher': false,
        'payment_due_days': 30,
      })),

      // stock_setting - إعدادات المخزون والفواتير
      setting('stock_setting', json.encode({
        'allowReturnWithoutInvoice': true,
        'showCustomerBalanceInInvoice': false,
        'showMonetaryInvoiceInCustomerAccount': true,
        'preventWhenSaleLessThanCost': true,
        'showCoseAmountInInvoice': true,
        'showCustomPhoneInInvoice': true,
        'showCostAmountInCategoryWhenAddInvoice': true,
        'showCostAmountInCategoryWhenAddInvoicePOS': false,
        'checkFundAndBankBalanceEnabledInInvoice': false,
        'isStockNegativeAllowed': false,
        'inventory_tracking': true,
        'low_stock_alert': 10,
        'default_warehouse': 1,
        'invoice_prefix': 'INV-',
        'invoice_starting_number': 1000,
        'quotation_prefix': 'QUO-',
        'return_prefix': 'RET-',
        'invoice_terms': 'شروط وأحكام الفاتورة',
        'invoice_footer': 'شكراً لتعاملكم معنا',
        'tax_enabled': false,
        'default_tax_rate': 15,
        'tax_name': 'ضريبة القيمة المضافة',
        'tax_inclusive_pricing': false,
      })),

      // backup_settings - إعدادات النسخ الاحتياطي
      setting('backup_settings', json.encode({
        'deviceSaveMethod': 1,
        'deviceSaveTime': null,
        'driveSaveMethod': 0,
        'hours': 24,
        'driveHours': 24,
      })),

      // pos_setting - إعدادات نقاط البيع
      setting('pos_setting', json.encode({
        'default_payment_method': 'cash',
        'default_customer': 'نقدي',
        'print_receipt_automatically': true,
        'receipt_printer_width': 80,
        'receipt_copies': 1,
        'allow_discount_per_line': true,
        'max_discount_percent': null,
        'cash_rounding_enabled': false,
        'cash_rounding_precision': 0.05,
        'barcode_enabled': true,
        'show_barcode_scanner': false,
        'enable_stock_alerts': true,
        'enable_customer_credit': false,
        'default_credit_limit': 0,
        'block_customer_over_limit': false,
        'allow_hold_orders': true,
        'allow_split_payment': true,
        'show_remaining_balance_in_receipt': true,
      }), category: 'POS'),
    ];
  }

  static Future<void> seed(Database db) async {
    // Insert settings using batch
    final batch = db.batch();
    for (final setting in defaultSettings) {
      batch.insert(
        'settings',
        setting,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<Map<String, dynamic>> getAllSettings(Database db) async {
    final results = await db.query('settings');
    final settings = <String, dynamic>{};
    
    for (final row in results) {
      final key = row['setting_key'] as String;
      final value = row['setting_value'] as String;
      
      try {
        settings[key] = json.decode(value);
      } catch (e) {
        settings[key] = value;
      }
    }
    
    return settings;
  }

  static Future<Map<String, dynamic>> getSettingByKey(
    Database db, 
    String key
  ) async {
    final results = await db.query(
      'settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    
    if (results.isNotEmpty) {
      final value = results.first['setting_value'] as String;
      try {
        return json.decode(value);
      } catch (e) {
        return {'value': value};
      }
    }
    
    return {};
  }

  static Future<void> updateSetting(
    Database db,
    String settingKey,
    Map<String, dynamic> newData,
  ) async {
    // Get current setting
    final currentSetting = await getSettingByKey(db, settingKey);
    
    // Merge with new data
    currentSetting.addAll(newData);
    
    // Update in database
    await db.update(
      'settings',
      {
        'setting_value': json.encode(currentSetting),
        'last_modifier_id': 1, // You should use actual user ID
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'concurrency_stamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'setting_key = ?',
      whereArgs: [settingKey],
    );
  }

  // Helper methods for specific settings
  static Future<Map<String, dynamic>> getPersonalInfo(Database db) async {
    return await getSettingByKey(db, 'personal_info');
  }

  static Future<Map<String, dynamic>> getPrinterInfo(Database db) async {
    return await getSettingByKey(db, 'printer_info');
  }

  static Future<Map<String, dynamic>> getStockSetting(Database db) async {
    return await getSettingByKey(db, 'stock_setting');
  }

  static Future<Map<String, dynamic>> getVoucherSetting(Database db) async {
    return await getSettingByKey(db, 'voucher_setting');
  }

  static Future<Map<String, dynamic>> getOtherSetting(Database db) async {
    return await getSettingByKey(db, 'other_setting');
  }
}
