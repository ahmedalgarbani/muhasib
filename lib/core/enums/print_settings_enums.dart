/// إعدادات الطباعة — يغطي print_settings_new.dart
/// 10 حالات switch على int/String كانت بلا Enum

enum PrintPaperType {
  a4(1, 'A4'),
  a5(0, 'A5'),
  letter(2, 'Letter');

  final int value;
  final String label;
  const PrintPaperType(this.value, this.label);

  static PrintPaperType fromValue(int value) {
    return PrintPaperType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PrintPaperType.a4,
    );
  }

  static PrintPaperType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  static PrintPaperType fromLabel(String label) {
    return PrintPaperType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => PrintPaperType.a4,
    );
  }

  int toJson() => value;
}

/// طريقة الطباعة — ملاحظة: الملفان القديم والجديد يستعملان قيمًا مختلفة
/// القديم: 0=Pdf/1=طابعة محلية، الجديد: 0=Pdf/1=Html — تم توحيدها هنا
enum PrintMethodType {
  pdf(0, 'Pdf'),
  localPrinter(1, 'طابعة محلية'),
  html(1, 'Html'); // alias للتوافق — نفس القيمة

  final int value;
  final String label;
  const PrintMethodType(this.value, this.label);

  static PrintMethodType fromValue(int value) {
    // كلاهما 1 → نرجع localPrinter كافتراضي
    return PrintMethodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PrintMethodType.pdf,
    );
  }

  static PrintMethodType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  static PrintMethodType fromLabel(String label) {
    final lower = label.toLowerCase();
    for (final e in values) {
      if (e.label.toLowerCase() == lower) return e;
    }
    return PrintMethodType.pdf;
  }

  int toJson() => value;
}

enum PrintConnectionType {
  viaProxy(1, 'عبر وسيط آخر'),
  notViaProxy(0, 'غير وسيط آخر'),
  direct(0, 'مباشر'), // alias
  network(2, 'شبكة');

  final int value;
  final String label;
  const PrintConnectionType(this.value, this.label);

  static PrintConnectionType fromValue(int value) {
    return PrintConnectionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PrintConnectionType.viaProxy,
    );
  }

  static PrintConnectionType? tryFromValue(int value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }

  static PrintConnectionType fromLabel(String label) {
    return PrintConnectionType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => PrintConnectionType.viaProxy,
    );
  }

  int toJson() => value;
}
