abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Map<String, dynamic> settings;

  SettingsLoaded({required this.settings});
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}

class SettingUpdated extends SettingsState {
  final String key;
  final dynamic value;

  SettingUpdated({required this.key, required this.value});
}
