import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocaleCubit extends HydratedCubit<Locale> {
  LocaleCubit() : super(const Locale('ar'));

  void updateLocale(Locale locale) => emit(locale);

  @override
  Locale? fromJson(Map<String, dynamic> json) {
    try {
      final languageCode = json['languageCode'] as String?;
      if (languageCode != null) {
        return Locale(languageCode);
      }
      return const Locale('ar');
    } catch (e) {
      return const Locale('ar');
    }
  }

  @override
  Map<String, dynamic>? toJson(Locale state) {
    try {
      return {
        'languageCode': state.languageCode,
      };
    } catch (e) {
      return null;
    }
  }
}
