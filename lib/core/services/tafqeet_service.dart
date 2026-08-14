class TafqeetService {
  static const List<String> _ones = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة',
  ];

  static const List<String> _teens = [
    'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر',
    'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
  ];

  static const List<String> _tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون',
  ];

  static const List<String> _hundreds = [
    '', 'مئة', 'مئتان', 'ثلاثمئة', 'أربعمئة', 'خمسمئة', 'ستمئة', 'سبعمئة', 'ثمانمئة', 'تسعمئة',
  ];

  static String convert(double amount, {String currencyName = 'ريال', String fractionName = 'هللة'}) {
    final totalCents = (amount * 100).round();
    final whole = totalCents ~/ 100;
    final fraction = totalCents % 100;

    if (whole == 0 && fraction == 0) return 'صفر $currencyName';

    final parts = <String>[
      if (whole > 0)
        _withCurrency(whole, currencyName)
      else
        'صفر $currencyName',
      if (fraction > 0) _withFraction(fraction, fractionName),
    ];
    return parts.join(' و');
  }

  static String _withCurrency(int n, String name) {
    final words = _wholeWords(n);
    if (n == 1) return '$name واحد';
    if (n == 2) return _dual(name);
    if (n <= 10) return '$words ${_plural(name)}';
    return '$words ${_accusative(name)}';
  }

  static String _withFraction(int n, String name) {
    final words = _wholeWords(n);
    if (n == 1) return '$name واحدة';
    if (n == 2) return _dual(name);
    if (n <= 10) return '$words ${_plural(name)}';
    return '$words $name';
  }

  static String _wholeWords(int n) {
    if (n == 0) return '';
    final billions = n ~/ 1000000000;
    final millions = (n % 1000000000) ~/ 1000000;
    final thousands = (n % 1000000) ~/ 1000;
    final rest = n % 1000;
    final parts = <String>[
      if (billions > 0) _groupWords(billions, 'مليار', 'ملياران', 'مليارات'),
      if (millions > 0) _groupWords(millions, 'مليون', 'مليونان', 'ملايين'),
      if (thousands > 0) _groupWords(thousands, 'ألف', 'ألفان', 'آلاف'),
      if (rest > 0) _threeDigits(rest),
    ];
    return parts.join(' و');
  }

  static String _groupWords(int n, String singular, String dual, String plural) {
    if (n == 1) return singular;
    if (n == 2) return dual;
    final words = _threeDigits(n);
    if (n <= 10) return '$words $plural';
    return '$words ${_accusative(singular)}';
  }

  static String _threeDigits(int n) {
    final hundreds = n ~/ 100;
    final rest = n % 100;
    final parts = <String>[
      if (hundreds > 0) _hundreds[hundreds],
      if (rest > 0) _twoDigits(rest),
    ];
    return parts.join(' و');
  }

  static String _twoDigits(int n) {
    if (n == 0) return '';
    if (n < 10) return _ones[n];
    if (n < 20) return _teens[n - 10];
    final ones = n % 10;
    if (ones == 0) return _tens[n ~/ 10];
    return '${_ones[ones]} و${_tens[n ~/ 10]}';
  }

  static String _dual(String name) {
    if (name.endsWith('ة')) return '${name.substring(0, name.length - 1)}تان';
    return '$nameان';
  }

  static String _plural(String name) {
    if (name.endsWith('ة')) return '${name.substring(0, name.length - 1)}ات';
    return '$nameات';
  }

  static String _accusative(String name) {
    if (name.endsWith('ة')) return '$nameً';
    return '$nameاً';
  }
}
