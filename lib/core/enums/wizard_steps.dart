// خطوات المعالجات (Wizards) — يغطي pos_page.dart:819 و improved_sales_invoice_screen.dart:390

enum PosStep {
  productSelection('١. الأصناف'),
  cartAndCustomer('٢. السلة والعميل'),
  paymentAndFinalize('٣. الدفع والإنهاء');

  final String title;
  const PosStep(this.title);

  String get label => title;

  static PosStep fromIndex(int index) {
    return PosStep.values.firstWhere(
      (e) => e.index == index,
      orElse: () => PosStep.productSelection,
    );
  }

  static PosStep? tryFromIndex(int index) {
    for (final e in values) {
      if (e.index == index) return e;
    }
    return null;
  }

  int toJson() => index;
}

enum SalesInvoiceStep {
  customer(1, 'معلومات العميل', 'اختر العميل وحدد تفاصيل الفاتورة'),
  products(2, 'الأصناف والمنتجات', 'أضف المنتجات المطلوبة'),
  totals(3, 'الخصومات والإجماليات', 'راجع الإجماليات وأضف الخصومات'),
  payment(4, 'طرق الدفع', 'حدد طريقة الدفع وأكمل العملية');

  final int stepNumber;
  final String title;
  final String subtitle;
  const SalesInvoiceStep(this.stepNumber, this.title, this.subtitle);

  String get label => title;

  static SalesInvoiceStep fromNumber(int number) {
    return SalesInvoiceStep.values.firstWhere(
      (e) => e.stepNumber == number,
      orElse: () => SalesInvoiceStep.customer,
    );
  }

  static SalesInvoiceStep? tryFromNumber(int number) {
    for (final e in values) {
      if (e.stepNumber == number) return e;
    }
    return null;
  }

  int toJson() => stepNumber;
}
