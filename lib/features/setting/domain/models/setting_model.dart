import 'dart:convert';

class SettingModel {
  final int? id;
  final String settingKey;
  final dynamic settingValue;
  final DateTime? creationTime;
  final DateTime? lastModificationTime;

  SettingModel({
    this.id,
    required this.settingKey,
    required this.settingValue,
    this.creationTime,
    this.lastModificationTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue is Map || settingValue is List
          ? jsonEncode(settingValue)
          : settingValue.toString(),
      'creation_time': creationTime?.millisecondsSinceEpoch,
      'last_modification_time': lastModificationTime?.millisecondsSinceEpoch,
    };
  }

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    String rawValue = map['setting_value']?.toString() ?? '';
    dynamic value;
    
    // Try to parse as JSON first
    try {
      value = jsonDecode(rawValue);
    } catch (_) {
      // If not JSON, use the raw value
      value = rawValue;
    }
    
    return SettingModel(
      id: map['id'],
      settingKey: map['setting_key'],
      settingValue: value,
      creationTime: map['creation_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['creation_time'] * 1000)
          : null,
      lastModificationTime: map['last_modification_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_modification_time'] * 1000)
          : null,
    );
  }
}

// Setting categories
class SettingCategory {
  static const String personalInfo = 'personal_info';
  static const String securityInfo = 'security_info';
  static const String printerInfo = 'printer_info';
  static const String otherSetting = 'other_setting';
  static const String voucherSetting = 'voucher_setting';
  static const String stockSetting = 'stock_setting';
  static const String backupSettings = 'backup_settings';
}
