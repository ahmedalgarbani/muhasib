import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/features/setting/data/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final ISettingsRepository repository;
  Map<String, dynamic> _settings = {};

  SettingsCubit({required this.repository}) : super(SettingsInitial());

  Map<String, dynamic> get settings => _settings;

  @override
  void emit(SettingsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadSettings() async {
    try {
      emit(SettingsLoading());
      _settings = await repository.getAllSettings();
      SettingsCache.update(_settings);
      emit(SettingsLoaded(settings: _settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    try {
      await repository.updateSetting(key, value);
      _settings[key] = value;
      SettingsCache.update(_settings);
      emit(SettingUpdated(key: key, value: value));
      emit(SettingsLoaded(settings: _settings));
    } catch (e) {
      emit(SettingsError('Failed to update setting: $e'));
    }
  }

  Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    try {
      emit(SettingsLoading());
      await repository.updateMultipleSettings(settings);
      _settings.addAll(settings);
      SettingsCache.update(_settings);
      emit(SettingsLoaded(settings: _settings));
    } catch (e) {
      emit(SettingsError('Failed to update settings: $e'));
    }
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings[key] ?? defaultValue;
  }

  Map<String, dynamic> getPersonalInfo() {
    final info = getSetting('personal_info', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getSecurityInfo() {
    final info = getSetting('security_info', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getPrinterInfo() {
    final info = getSetting('printer_info', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getOtherSettings() {
    final info = getSetting('other_setting', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getVoucherSettings() {
    final info = getSetting('voucher_setting', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getStockSettings() {
    final info = getSetting('stock_setting', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getBackupSettings() {
    final info = getSetting('backup_settings', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Map<String, dynamic> getPosSettings() {
    final info = getSetting('pos_setting', defaultValue: {});
    return info is Map<String, dynamic> ? info : {};
  }

  Future<void> initializeSettings() async {
    try {
      await repository.initializeDefaultSettings();
      await loadSettings();
    } catch (e) {
      emit(SettingsError('Failed to initialize settings: $e'));
    }
  }
}
