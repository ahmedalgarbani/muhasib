/// ثوابت مركزية لقاعدة البيانات — لا تستخدم Magic Numbers في الجداول أو المولدات
class AppDbConstants {
  /// الحد الأدنى للطابع الزمني المسموح (01/01/2000 00:00:00 UTC) — مستخدم في CHECK(creation_time > ...)
  static const int minValidTimestamp = 946674000;

  /// طول الحشو الافتراضي لتسلسل الأرقام (padLeft)
  static const int defaultNumberPadding = 6;

  /// جملة CHECK الموحدة للطوابع الزمنية
  static const String creationTimeCheck = 'CHECK(creation_time > $minValidTimestamp)';
  static const String modificationTimeCheck = 'CHECK(last_modification_time > $minValidTimestamp)';

  const AppDbConstants._();
}
