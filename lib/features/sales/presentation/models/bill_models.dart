import 'package:flutter/material.dart';

class Bill {
  final String id;
  final String customer;
  final String date;
  final double total;
  final double paid;
  final double remaining;
  final BillStatus status;
  final PaymentMethod paymentMethod;
  final int itemsCount;

  Bill({
    required this.id,
    required this.customer,
    required this.date,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.status,
    required this.paymentMethod,
    required this.itemsCount,
  });

  Bill copyWith({
    String? id,
    String? customer,
    String? date,
    double? total,
    double? paid,
    double? remaining,
    BillStatus? status,
    PaymentMethod? paymentMethod,
    int? itemsCount,
  }) {
    return Bill(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      date: date ?? this.date,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }
}

enum BillStatus { paid, partial, unpaid }

enum PaymentMethod { cash, bank, deferred, mixed }

class BillStats {
  final int total;
  final int paid;
  final int partial;
  final int unpaid;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  BillStats({
    required this.total,
    required this.paid,
    required this.partial,
    required this.unpaid,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });
}

class BillConstants {
  static const Map<BillStatus, BillStatusConfig> statusConfig = {
    BillStatus.paid: BillStatusConfig(
      label: 'الفاتورة مدفوعة',
      color: Color(0xFFD1FAE5),
      textColor: Color(0xFF065F46),
      icon: '✅',
    ),
    BillStatus.partial: BillStatusConfig(
      label: 'دفعة جزئية',
      color: Color(0xFFFEF3C7),
      textColor: Color(0xFF92400E),
      icon: '🌓',
    ),
    BillStatus.unpaid: BillStatusConfig(
      label: 'غير مدفوعة',
      color: Color(0xFFFEE2E2),
      textColor: Color(0xFF991B1B),
      icon: '⛔',
    ),
  };

  static const Map<PaymentMethod, PaymentMethodConfig> paymentMethodConfig = {
    PaymentMethod.cash: PaymentMethodConfig(
      label: 'نقداً',
      icon: '💵',
    ),
    PaymentMethod.bank: PaymentMethodConfig(
      label: 'حوالة بنكية',
      icon: '🏦',
    ),
    PaymentMethod.deferred: PaymentMethodConfig(
      label: 'آجل',
      icon: '⏳',
    ),
    PaymentMethod.mixed: PaymentMethodConfig(
      label: 'مدفوع مختلط',
      icon: '🔄',
    ),
  };
}

class BillStatusConfig {
  final String label;
  final Color color;
  final Color textColor;
  final String icon;

  const BillStatusConfig({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });
}

class PaymentMethodConfig {
  final String label;
  final String icon;

  const PaymentMethodConfig({
    required this.label,
    required this.icon,
  });
}
