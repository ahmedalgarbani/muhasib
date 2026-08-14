import 'package:muhasib/core/services/settings_cache.dart';

class Customer {
  final String id;
  final String name;
  final double balance;
  final double creditLimit;
  final String? phone;
  final int type; // 1=customer, 2=supplier
  final String? address;
  final int? accountId;

  Customer({
    required this.id,
    required this.name,
    this.balance = 0,
    this.creditLimit = 0,
    this.phone,
    this.type = 1,
    this.address,
    this.accountId,
  });

  bool get hasDebt => balance > 0;
  bool get isCredit => type == 2;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      phone: json['phone'],
      type: json['type'] ?? 1,
      address: json['address'],
      accountId: json['accountId'] is int ? json['accountId'] : int.tryParse(json['accountId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'creditLimit': creditLimit,
      'phone': phone,
      'type': type,
      'address': address,
      'accountId': accountId,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    double? balance,
    double? creditLimit,
    String? phone,
    int? type,
    String? address,
    int? accountId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      accountId: accountId ?? this.accountId,
    );
  }
}

class InvoiceItem {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String unit;
  final int stock;
  int quantity;

  // Unit conversion fields
  final int? unitId;
  final double conversionRate;
  final int packaging;
  double? baseQuantity;
  final double? costPrice;
  final bool trackInventory;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.unit,
    required this.stock,
    this.quantity = 1,
    this.unitId,
    this.conversionRate = 1.0,
    this.packaging = 1,
    this.baseQuantity,
    this.costPrice,
    this.trackInventory = true,
  }) {
    // Calculate base quantity if not provided
    baseQuantity ??= quantity * packaging * conversionRate;
  }

  double get total => price * quantity;

  /// Get the quantity for inventory operations
  double get inventoryQuantity => baseQuantity ?? (quantity * packaging * conversionRate);

  /// Update base quantity when quantity changes
  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    baseQuantity = quantity * packaging * conversionRate;
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      price: json['price'].toDouble(),
      unit: json['unit'],
      stock: json['stock'],
      quantity: json['quantity'] ?? 1,
      unitId: json['unit_id'] as int?,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 1.0,
      packaging: json['packaging'] as int? ?? 1,
      baseQuantity: (json['base_quantity'] as num?)?.toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      trackInventory: json['track_inventory'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'unit': unit,
      'stock': stock,
      'quantity': quantity,
      'unit_id': unitId,
      'conversion_rate': conversionRate,
      'packaging': packaging,
      'base_quantity': baseQuantity ?? inventoryQuantity,
      'cost_price': costPrice,
      'track_inventory': trackInventory,
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    String? unit,
    int? stock,
    int? quantity,
    int? unitId,
    double? conversionRate,
    int? packaging,
    double? baseQuantity,
    double? costPrice,
    bool? trackInventory,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      conversionRate: conversionRate ?? this.conversionRate,
      packaging: packaging ?? this.packaging,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      costPrice: costPrice ?? this.costPrice,
      trackInventory: trackInventory ?? this.trackInventory,
    );
  }
}

enum DiscountType { amount, percent }

class Discount {
  final DiscountType type;
  final double value;

  Discount({required this.type, required this.value});

  double calculate(double subtotal) {
    if (type == DiscountType.percent) {
      return (subtotal * value) / 100;
    }
    return value;
  }

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      type: json['type'] == 'percent'
          ? DiscountType.percent
          : DiscountType.amount,
      value: json['value'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == DiscountType.percent ? 'percent' : 'amount',
      'value': value,
    };
  }

  Discount copyWith({DiscountType? type, double? value}) {
    return Discount(type: type ?? this.type, value: value ?? this.value);
  }
}

enum PaymentMethod { cash, bank, deferred }

class Payment {
  final String? id;
  final PaymentMethod method;
  final double amount;
  final dynamic details;
  final DateTime? date;

  Payment({
    this.id,
    required this.method,
    required this.amount,
    this.details,
    this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    PaymentMethod method;
    switch (json['method']) {
      case 'cash':
        method = PaymentMethod.cash;
        break;
      case 'bank':
        method = PaymentMethod.bank;
        break;
      case 'deferred':
        method = PaymentMethod.deferred;
        break;
      default:
        method = PaymentMethod.cash;
    }

    return Payment(
      id: json['id'],
      method: method,
      amount: json['amount'].toDouble(),
      details: json['details'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    String methodStr;
    switch (method) {
      case PaymentMethod.cash:
        methodStr = 'cash';
        break;
      case PaymentMethod.bank:
        methodStr = 'bank';
        break;
      case PaymentMethod.deferred:
        methodStr = 'deferred';
        break;
    }

    return {
      if (id != null) 'id': id,
      'method': methodStr,
      'amount': amount,
      'details': details,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    PaymentMethod? method,
    double? amount,
    dynamic details,
    DateTime? date,
  }) {
    return Payment(
      id: id ?? this.id,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      details: details ?? this.details,
      date: date ?? this.date,
    );
  }
}

class Invoice {
  final String number;
  Customer? customer;
  DateTime date;
  String currency;
  String warehouse;
  List<InvoiceItem> items;
  Discount discount;
  double otherCharges;
  List<Payment> payments;
  String notes;

  Invoice({
    required this.number,
    this.customer,
    required this.date,
    this.currency = 'ريال سعودي',
    this.warehouse = 'المخزن الرئيسي',
    this.items = const [],
    required this.discount,
    this.otherCharges = 0,
    this.payments = const [],
    this.notes = '',
  });

  // Computed properties
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get discountAmount => discount.calculate(subtotal);
  double get taxAmount {
    if (!SettingsCache.taxEnabled) return 0;
    final taxable = subtotal - discountAmount;
    if (taxable <= 0) return 0;
    if (SettingsCache.taxInclusivePricing) {
      return taxable *
          SettingsCache.defaultTaxRate /
          (100 + SettingsCache.defaultTaxRate);
    }
    return taxable * SettingsCache.defaultTaxRate / 100;
  }

  double get total => subtotal - discountAmount + otherCharges + taxAmount;
  double get paid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get remaining => total - paid;

  bool get isValid => customer != null && items.isNotEmpty;
  bool get isFullyPaid => remaining == 0;
  bool get isPartiallyPaid => paid > 0 && remaining > 0;
  bool get isUnpaid => paid == 0;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      number: json['number'],
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      date: DateTime.parse(json['date']),
      currency: json['currency'] ?? 'ريال سعودي',
      warehouse: json['warehouse'] ?? 'المخزن الرئيسي',
      items:
          (json['items'] as List?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      discount: Discount.fromJson(json['discount']),
      otherCharges: json['otherCharges']?.toDouble() ?? 0,
      payments:
          (json['payments'] as List?)
              ?.map((payment) => Payment.fromJson(payment))
              .toList() ??
          [],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'customer': customer?.toJson(),
      'date': date.toIso8601String(),
      'currency': currency,
      'warehouse': warehouse,
      'items': items.map((item) => item.toJson()).toList(),
      'discount': discount.toJson(),
      'otherCharges': otherCharges,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'notes': notes,
    };
  }

  Invoice copyWith({
    String? number,
    Customer? customer,
    DateTime? date,
    String? currency,
    String? warehouse,
    List<InvoiceItem>? items,
    Discount? discount,
    double? otherCharges,
    List<Payment>? payments,
    String? notes,
  }) {
    return Invoice(
      number: number ?? this.number,
      customer: customer ?? this.customer,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      warehouse: warehouse ?? this.warehouse,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      otherCharges: otherCharges ?? this.otherCharges,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
    );
  }
}
