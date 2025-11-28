import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class SettingsSeeder {
  static Future<void> seed(Database db) async {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final settings = [
      // personal_info - معلومات الشركة
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'personal_info',
        'setting_value': '''{
          "name": "اسم الشركة",
          "address": "عنوان الشركة",
          "logoPath": null,
          "signature": null,
          "nameFrn": "Company Name",
          "AddressFrn": "Company Address",
          "taxNo": null,
          "phone": "0500000000",
          "phoneFrn": "0500000000",
          "sealingPath": null,
          "company_email": "info@company.com",
          "company_commercial_register": "",
          "fiscal_year_start": "01-01",
          "fiscal_year_end": "12-31"
        }'''
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'initial_setup_done',
        'setting_value': 'false',
        'setting_type': 'BOOLEAN',
        'description': 'Flag indicating whether the onboarding wizard was completed',
        'category': 'General',
      },
      
      // security_info - إعدادات الأمان
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'security_info',
        'setting_value': '''{
          "isActive": false,
          "password": null,
          "backup_enabled": true,
          "backup_frequency": "daily",
          "initial_setup_done": false
        }'''
      },
      
      // printer_info - إعدادات الطباعة
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'printer_info',
        'setting_value': '''{
          "printType": 1,
          "printSize": 0,
          "printerConnect": 1,
          "showHeaderData": true,
          "repateHeaderInAllPages": true,
          "showDate": false,
          "showTime": false,
          "showSignatureAndSealingInVoucher": 2,
          "showSignatureAndSealingInInvoice": 2,
          "showSignatureAndSealingInJournal": 2,
          "tafqeetAmount": false,
          "showHeaderCompanyName": true,
          "showHeaderCompanyAddress": true,
          "showHeaderCompanyPhone": true,
          "printFontType": "assets/fonts/Alexandria-Regular.ttf",
          "print_paper_size": "A4",
          "print_orientation": "portrait",
          "print_copies": 1,
          "show_print_preview": true
        }'''
      },
      
      // other_setting - إعدادات النظام العامة
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'other_setting',
        'setting_value': '''{
          "dateFormat": 0,
          "timeFormat": 0,
          "decimalNoInput": 7,
          "decimalNoOutput": 2,
          "debit": "مدين",
          "credit": "دائن",
          "showStockModule": true,
          "showAccountantAdvanceModule": true,
          "updateCostAmountType": 2,
          "showTaxModule": false,
          "homeScrrenType": 1,
          "useMiniHasib": false,
          "showBackupNotifyWhenCloseApp": true,
          "fontScale": 1,
          "language": "ar",
          "timezone": "Asia/Riyadh",
          "default_currency": "SAR",
          "decimal_places": 2,
          "thousands_separator": ",",
          "decimal_separator": "."
        }'''
      },
      
      // voucher_setting - إعدادات السندات
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'voucher_setting',
        'setting_value': '''{
          "paymentVoucherLine1": "الاخ",
          "paymentVoucherLine2": "عليكم مبلغ",
          "receiptVoucherVoucherLine1": "الاخ",
          "receiptVoucherVoucherLine2": "لكم مبلغ",
          "paymentVoucherSignature": true,
          "paymentVoucherFirstSignature": "المستلم",
          "paymentVoucherSecondSignature": "مدير الحسابات",
          "paymentVoucherThirdSignature": "الصندوق",
          "paymentVoucherFourthSignature": "المدير العام",
          "receiptVoucherSignature": true,
          "receiptVoucherFirstSignature": "المستلم",
          "receiptVoucherSecondSignature": "مدير الحسابات",
          "receiptVoucherThirdSignature": "الصندوق",
          "receiptVoucherFourthSignature": "المدير العام",
          "notesInBotton": null,
          "allowMultiCurrencyInVoucher": false,
          "showAccountBalanceInVoucher": false,
          "checkFundAndBankBalanceEnabledInVoucher": false,
          "payment_due_days": 30
        }'''
      },
      
      // stock_setting - إعدادات المخزون والفواتير
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'stock_setting',
        'setting_value': '''{
          "allowReturnWithoutInvoice": true,
          "showCustomerBalanceInInvoice": false,
          "showMonetaryInvoiceInCustomerAccount": true,
          "preventWhenSaleLessThanCost": true,
          "showCoseAmountInInvoice": true,
          "showCustomPhoneInInvoice": true,
          "showCostAmountInCategoryWhenAddInvoice": true,
          "showCostAmountInCategoryWhenAddInvoicePOS": false,
          "checkFundAndBankBalanceEnabledInInvoice": false,
          "isStockNegativeAllowed": false,
          "inventory_tracking": true,
          "low_stock_alert": 10,
          "default_warehouse": 1,
          "invoice_prefix": "INV-",
          "invoice_starting_number": 1000,
          "quotation_prefix": "QUO-",
          "return_prefix": "RET-",
          "invoice_terms": "شروط وأحكام الفاتورة",
          "invoice_footer": "شكراً لتعاملكم معنا",
          "tax_enabled": false,
          "default_tax_rate": 15,
          "tax_name": "ضريبة القيمة المضافة",
          "tax_inclusive_pricing": false
        }'''
      },
      
      // backup_settings - إعدادات النسخ الاحتياطي
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'concurrency_stamp': currentTimestamp,
        'extra_properties': '',
        'creation_time': currentTimestamp,
        'last_modification_time': currentTimestamp,
        'setting_key': 'backup_settings',
        'setting_value': '''{
          "deviceSaveMethod": 1,
          "deviceSaveTime": null,
          "driveSaveMethod": 0,
          "hours": 24,
          "driveHours": 24
        }'''
      }
    ];

    // Insert settings using batch
    final batch = db.batch();
    for (final setting in settings) {
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
