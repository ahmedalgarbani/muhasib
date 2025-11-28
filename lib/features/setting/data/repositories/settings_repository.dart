import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:muhasib/features/setting/domain/models/setting_model.dart';

abstract class ISettingsRepository {
  Future<Map<String, dynamic>> getAllSettings();
  Future<dynamic> getSetting(String key);
  Future<void> updateSetting(String key, dynamic value);
  Future<void> updateMultipleSettings(Map<String, dynamic> settings);
  Future<void> initializeDefaultSettings();
}

class SettingsRepository implements ISettingsRepository {
  final Database database;

  SettingsRepository({required this.database});

  @override
  Future<Map<String, dynamic>> getAllSettings() async {
    final results = await database.query('settings');
    final settings = <String, dynamic>{};
    
    for (final row in results) {
      final model = SettingModel.fromMap(row);
      settings[model.settingKey] = model.settingValue;
    }
    
    return settings;
  }

  @override
  Future<dynamic> getSetting(String key) async {
    final results = await database.query(
      'settings',
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    final model = SettingModel.fromMap(results.first);
    return model.settingValue;
  }

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    final valueString = value is Map || value is List
        ? jsonEncode(value)
        : value.toString();
    
    await database.update(
      'settings',
      {
        'setting_value': valueString,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    final batch = database.batch();
    
    for (final entry in settings.entries) {
      final valueString = entry.value is Map || entry.value is List
          ? jsonEncode(entry.value)
          : entry.value.toString();
      
      batch.update(
        'settings',
        {
          'setting_value': valueString,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'setting_key = ?',
        whereArgs: [entry.key],
      );
    }
    
    await batch.commit();
  }

  @override
  Future<void> initializeDefaultSettings() async {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final defaultSettings = [
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'personal_info',
        'setting_value': jsonEncode({
          'name': 'حسيب',
          'address': 'صنعاء',
          'logoPath': null,
          'signature': null,
          'nameFrn': 'Hasib',
          'AddressFrn': 'Sana\'a',
          'taxNo': null,
          'phone': '967782767927',
          'phoneFrn': '967782767927',
          'sealingPath': null,
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'initial_setup_done',
        'setting_value': 'false',
        'setting_type': 'BOOLEAN',
        'description': 'Flag that marks whether the onboarding wizard was completed',
        'category': 'General',
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'security_info',
        'setting_value': jsonEncode({
          'isActive': false,
          'password': null,
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'printer_info',
        'setting_value': jsonEncode({
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
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'other_setting',
        'setting_value': jsonEncode({
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
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'voucher_setting',
        'setting_value': jsonEncode({
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
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'stock_setting',
        'setting_value': jsonEncode({
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
        }),
      },
      {
        'creator_id': 1,
        'last_modifier_id': 1,
        'creation_time': currentTime,
        'last_modification_time': currentTime,
        'setting_key': 'backup_settings',
        'setting_value': jsonEncode({
          'deviceSaveMethod': 1,
          'deviceSaveTime': null,
          'driveSaveMethod': 0,
          'hours': 24,
          'driveHours': 24,
        }),
      },
    ];

    final batch = database.batch();
    for (final setting in defaultSettings) {
      batch.insert(
        'settings',
        setting,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit();
  }
}
