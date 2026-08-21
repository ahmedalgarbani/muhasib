/// خيارات الفرز — يغطي sale_page_body.dart:175 و transactions_report_data_source.dart:69,102

enum InvoiceSortOption {
  dateDesc('date-desc', 'التاريخ (الأحدث أولاً)'),
  dateAsc('date-asc', 'التاريخ (الأقدم أولاً)'),
  totalDesc('total-desc', 'المبلغ (الأعلى أولاً)'),
  totalAsc('total-asc', 'المبلغ (الأقل أولاً)');

  final String code;
  final String labelAr;
  const InvoiceSortOption(this.code, this.labelAr);

  String get label => labelAr;

  static InvoiceSortOption fromCode(String code) {
    return InvoiceSortOption.values.firstWhere(
      (e) => e.code == code,
      orElse: () => InvoiceSortOption.dateDesc,
    );
  }

  static InvoiceSortOption? tryFromCode(String code) {
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
}

enum TransactionSortBy {
  date('date', 'entry_date'),
  amount('amount', 'total_debit');

  final String code;
  final String column;
  const TransactionSortBy(this.code, this.column);

  String get label => code;

  static TransactionSortBy fromCode(String? code) {
    if (code == 'amount') return TransactionSortBy.amount;
    return TransactionSortBy.date;
  }

  static TransactionSortBy? tryFromCode(String? code) {
    if (code == null) return null;
    for (final e in values) {
      if (e.code == code) return e;
    }
    return null;
  }

  String toJson() => code;
}
