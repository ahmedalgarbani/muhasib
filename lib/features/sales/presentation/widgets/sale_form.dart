// lib/models/customer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:intl/intl.dart';

class Customer {
  final String id;
  final String name;
  final double balance;
  final double creditLimit;

  Customer({
    required this.id,
    required this.name,
    required this.balance,
    required this.creditLimit,
  });

  bool get hasDebt => balance < 0;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
      creditLimit: json['creditLimit'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'creditLimit': creditLimit,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    double? balance,
    double? creditLimit,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }
}

// lib/models/invoice_item.dart

class InvoiceItem {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String unit;
  final int stock;
  int quantity;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.unit,
    required this.stock,
    this.quantity = 1,
  });

  double get total => price * quantity;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      price: json['price'].toDouble(),
      unit: json['unit'],
      stock: json['stock'],
      quantity: json['quantity'] ?? 1,
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
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      quantity: quantity ?? this.quantity,
    );
  }
}

// lib/models/discount.dart

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

// lib/models/payment.dart

enum PaymentMethod { cash, bank, deferred }

class Payment {
  final PaymentMethod method;
  final double amount;
  final Map<String, dynamic>? details;

  Payment({required this.method, required this.amount, this.details});

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
      method: method,
      amount: json['amount'].toDouble(),
      details: json['details'],
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

    return {'method': methodStr, 'amount': amount, 'details': details};
  }

  Payment copyWith({
    PaymentMethod? method,
    double? amount,
    Map<String, dynamic>? details,
  }) {
    return Payment(
      method: method ?? this.method,
      amount: amount ?? this.amount,
      details: details ?? this.details,
    );
  }
}

// lib/models/invoice.dart
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
  double get total => subtotal - discountAmount + otherCharges;
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
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary Colors
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);

  // Status Colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // Grayscale
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF3F4F6);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey300 = Color(0xFFD1D5DB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey600 = Color(0xFF4B5563);
  static const grey700 = Color(0xFF374151);
  static const grey800 = Color(0xFF1F2937);
  static const grey900 = Color(0xFF111827);

  // Background
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;

  // Text
  static const textPrimary = grey900;
  static const textSecondary = grey600;
  static const textDisabled = grey400;

  // Border
  static const border = grey200;
  static const borderDark = grey300;
}

// lib/core/theme/app_spacing.dart

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// lib/core/theme/app_text_styles.dart

class AppTextStyles {
  // Headlines
  static const headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const headline3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Titles
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Caption
  static const caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const captionMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Small
  static const small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const smallBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Buttons
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static const buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
}

// lib/core/theme/app_theme.dart

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        error: AppColors.error,
        background: AppColors.background,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headline3,
        iconTheme: IconThemeData(color: AppColors.grey900),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.body,
        hintStyle: AppTextStyles.caption,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey900,
          side: const BorderSide(color: AppColors.grey300, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.grey900),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.grey900, size: 24),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

// lib/core/constants/app_constants.dart

class AppConstants {
  // Touch Targets (minimum 44px for accessibility)
  static const double minTouchTarget = 44.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Animation Duration
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // Default Values
  static const String defaultCurrency = 'ريال سعودي';
  static const String defaultWarehouse = 'المخزن الرئيسي';

  // Validation
  static const int maxNotesLength = 500;
  static const int maxItemsPerInvoice = 100;

  // Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String currencyFormat = '#,##0.00';
}

// lib/core/utils/number_formatter.dart

class NumberFormatter {
  static String formatCurrency(double amount, {String symbol = 'ريال'}) {
    final formatter = NumberFormat('#,##0', 'ar');
    return '${formatter.format(amount)} $symbol';
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.##', 'ar');
    return formatter.format(number);
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

// lib/core/utils/date_formatter.dart

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm', 'ar').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return formatDate(date);
    }
  }
}
// lib/widgets/buttons/primary_button.dart

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;
  final double? height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isFullWidth ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text, style: AppTextStyles.buttonLarge),
                ],
              ),
      ),
    );
  }
}

// lib/widgets/buttons/secondary_button.dart

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final double? height;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.grey300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isFullWidth ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
            Text(
              text,
              style: AppTextStyles.button.copyWith(color: AppColors.grey900),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/widgets/cards/item_card.dart

class ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormatter.formatCurrency(item.price)} × ${item.quantity} = ${NumberFormatter.formatCurrency(item.total)}',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed: onDecrement,
                  isPrimary: false,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: AppTextStyles.title.copyWith(fontSize: 24),
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: onIncrement,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.grey900,
          size: 24,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// lib/widgets/common/expandable_section.dart

class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const ExpandableSection({
    Key? key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) widget.child,
      ],
    );
  }
}

// lib/widgets/common/empty_state.dart

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    Key? key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// lib/widgets/invoice/sticky_invoice_header.dart

class StickyInvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onCustomerTap;

  const StickyInvoiceHeader({
    Key? key,
    required this.invoice,
    required this.onCustomerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.grey200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(invoice.number, style: AppTextStyles.title),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: onCustomerTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invoice.customer?.name ?? 'اختر العميل',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('yyyy-MM-dd').format(invoice.date),
                style: AppTextStyles.small,
              ),
            ],
          ),
          if (invoice.customer?.hasDebt ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تحذير: العميل لديه مديونية ${NumberFormatter.formatCurrency(invoice.customer!.balance.abs())}',
              style: AppTextStyles.small.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountInfo('الإجمالي', invoice.total, AppColors.grey900),
              _buildAmountInfo('المدفوع', invoice.paid, AppColors.success),
              _buildAmountInfo('المتبقي', invoice.remaining, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        Text(
          NumberFormatter.formatNumber(amount),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// lib/widgets/invoice/step_indicator.dart

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepIndicator({
    Key? key,
    required this.currentStep,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            final stepIndex = index ~/ 2;
            final isActive = currentStep >= stepIndex + 1;
            final isCompleted = currentStep > stepIndex + 1;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : AppColors.grey200,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.grey600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[stepIndex],
                    style: AppTextStyles.small.copyWith(
                      color: isActive ? AppColors.primary : AppColors.grey600,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          } else {
            final isActive = currentStep > (index ~/ 2) + 1;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 28),
                color: isActive ? AppColors.primary : AppColors.grey200,
              ),
            );
          }
        }),
      ),
    );
  }
}
// lib/widgets/bottom_sheets/customer_bottom_sheet.dart

class CustomerBottomSheet extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onSelect;

  const CustomerBottomSheet({
    Key? key,
    required this.customers,
    required this.onSelect,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required List<Customer> customers,
    required Function(Customer) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CustomerBottomSheet(customers: customers, onSelect: onSelect),
    );
  }

  @override
  State<CustomerBottomSheet> createState() => _CustomerBottomSheetState();
}

class _CustomerBottomSheetState extends State<CustomerBottomSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = widget.customers
        .where((c) => c.name.contains(_searchQuery))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('اختيار العميل', style: AppTextStyles.title),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن عميل...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return InkWell(
                        onTap: () {
                          widget.onSelect(customer);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.grey200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: AppTextStyles.body),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الرصيد: ${NumberFormatter.formatCurrency(customer.balance)}',
                                    style: AppTextStyles.small.copyWith(
                                      color: customer.hasDebt
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    'الحد: ${NumberFormatter.formatCurrency(customer.creditLimit)}',
                                    style: AppTextStyles.small,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// lib/widgets/bottom_sheets/add_item_bottom_sheet.dart

class AddItemBottomSheet extends StatefulWidget {
  final InvoiceItem item;
  final Function(InvoiceItem) onAdd;

  const AddItemBottomSheet({Key? key, required this.item, required this.onAdd})
    : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required InvoiceItem item,
    required Function(InvoiceItem) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddItemBottomSheet(item: item, onAdd: onAdd),
      ),
    );
  }

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  late int _quantity;
  late double _price;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _price = widget.item.price;
    _priceController.text = _price.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إضافة صنف', style: AppTextStyles.title),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  'السعر: ${NumberFormatter.formatCurrency(widget.item.price)} | متوفر: ${widget.item.stock} ${widget.item.unit}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('الكمية', style: AppTextStyles.body),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildQuantityButton(Icons.remove, () {
                if (_quantity > 1) setState(() => _quantity--);
              }, false),
              Expanded(
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildQuantityButton(
                Icons.add,
                () => setState(() => _quantity++),
                true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'السعر'),
            onChanged: (value) =>
                setState(() => _price = double.tryParse(value) ?? _price),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي:', style: AppTextStyles.body),
                Text(
                  NumberFormatter.formatCurrency(_price * _quantity),
                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: 'إضافة إلى الفاتورة',
            onPressed: () {
              widget.onAdd(
                widget.item.copyWith(quantity: _quantity, price: _price),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onPressed,
    bool isPrimary,
  ) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.grey200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.grey900,
          size: 28,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
// lib/screens/sales_invoice/sales_invoice_screen.dart

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  int _currentStep = 1;
  late Invoice _invoice;

  // Sample data
  final List<Customer> _customers = [
    Customer(id: '1', name: 'محمد أحمد', balance: 5000, creditLimit: 10000),
    Customer(
      id: '2',
      name: 'شركة النور للتجارة',
      balance: -2000,
      creditLimit: 50000,
    ),
    Customer(id: '3', name: 'فاطمة علي', balance: 0, creditLimit: 5000),
  ];

  List<InvoiceItem> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _invoice = Invoice(
      number: 'INV-2025-001',
      date: DateTime.now(),
      items: [],
      discount: Discount(type: DiscountType.amount, value: 0),
      payments: [],
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Load products from database
    context.read<ProductsCubit>().loadProducts();
  }

  void _updateInvoice(Invoice invoice) {
    setState(() => _invoice = invoice);
  }

  void _nextStep() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  void _showCustomerBottomSheet() {
    CustomerBottomSheet.show(
      context,
      customers: _customers,
      onSelect: (customer) {
        setState(() => _invoice = _invoice.copyWith(customer: customer));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep == 1 || _currentStep == 2)
              StickyInvoiceHeader(
                invoice: _invoice,
                onCustomerTap: _showCustomerBottomSheet,
              ),
            StepIndicator(
              currentStep: _currentStep,
              steps: const ['العميل', 'الأصناف', 'الدفع', 'المراجعة'],
            ),
            Expanded(
              child: IndexedStack(
                index: _currentStep - 1,
                children: [
                  Step1Customer(
                    invoice: _invoice,
                    customers: _customers,
                    onInvoiceUpdate: _updateInvoice,
                    onNext: _nextStep,
                    onShowCustomerSheet: _showCustomerBottomSheet,
                  ),
                  BlocBuilder<ProductsCubit, ProductsState>(
                    builder: (context, state) {
                      if (state is ProductsLoaded) {
                        // Convert ProductEntity to InvoiceItem
                        _availableItems = state.products.where((p) => p.isActive).map((product) {
                          return InvoiceItem(
                            id: product.id?.toString() ?? '',
                            name: product.name,
                            barcode: product.barcodeNo,
                            price: product.sellAmount ?? product.sellLocalAmount ?? 0,
                            unit: 'قطعة', // Default unit, you can fetch from unit entity
                            stock: product.quantity.toInt(),
                          );
                        }).toList();
                      }
                      
                      return Step2Items(
                        invoice: _invoice,
                        availableItems: _availableItems,
                        onInvoiceUpdate: _updateInvoice,
                        onNext: _nextStep,
                        onPrevious: _previousStep,
                      );
                    },
                  ),
                  Step3Payment(
                    invoice: _invoice,
                    onInvoiceUpdate: _updateInvoice,
                    onNext: _nextStep,
                    onPrevious: _previousStep,
                  ),
                  Step4Review(
                    invoice: _invoice,
                    onPrevious: _previousStep,
                    onSave: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/sales_invoice/steps/step_1_customer.dart

class Step1Customer extends StatefulWidget {
  final Invoice invoice;
  final List<Customer> customers;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onShowCustomerSheet;

  const Step1Customer({
    Key? key,
    required this.invoice,
    required this.customers,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onShowCustomerSheet,
  }) : super(key: key);

  @override
  State<Step1Customer> createState() => _Step1CustomerState();
}

class _Step1CustomerState extends State<Step1Customer> {
  late TextEditingController _notesController;
  List<WarehouseEntity> _warehouses = [];
  List<CurrencyEntity> _currencies = [];
  int? _selectedWarehouseId;
  int? _selectedCurrencyId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes);
    _loadWarehousesAndCurrencies();
  }
  
  Future<void> _loadWarehousesAndCurrencies() async {
    // Load warehouses
    context.read<WarehousesCubit>().loadActiveWarehouses();
    // Load currencies
    context.read<CurrenciesCubit>().loadAllCurrencies();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('العميل *', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onShowCustomerSheet,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: widget.invoice.customer != null
                            ? AppColors.primary
                            : AppColors.grey300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.invoice.customer != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.invoice.customer!.name,
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الرصيد: ${NumberFormatter.formatCurrency(widget.invoice.customer!.balance)} | الحد: ${NumberFormatter.formatCurrency(widget.invoice.customer!.creditLimit)}',
                                style: AppTextStyles.small,
                              ),
                            ],
                          )
                        : Text(
                            'اختر العميل',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التاريخ', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: widget.invoice.date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          widget.onInvoiceUpdate(
                            widget.invoice.copyWith(date: date),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${widget.invoice.date.year}-${widget.invoice.date.month.toString().padLeft(2, '0')}-${widget.invoice.date.day.toString().padLeft(2, '0')}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('العملة', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.sm),
                    BlocBuilder<CurrenciesCubit, CurrenciesState>(
                      builder: (context, state) {
                        if (state is CurrenciesLoaded) {
                          _currencies = state.currencies;
                          // Set default currency if not selected
                          if (_selectedCurrencyId == null && _currencies.isNotEmpty) {
                            // Find local currency or use first one
                            CurrencyEntity? mainCurrency;
                            try {
                              mainCurrency = _currencies.firstWhere((c) => c.isLocalCurrency == true);
                            } catch (e) {
                              mainCurrency = _currencies.first;
                            }
                            _selectedCurrencyId = mainCurrency.id;
                          }
                          
                          return DropdownButtonFormField<int>(
                            value: _selectedCurrencyId,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.grey50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.grey200, width: 2),
                              ),
                            ),
                            items: _currencies.map((currency) {
                              return DropdownMenuItem<int>(
                                value: currency.id,
                                child: Text('${currency.name} (${currency.code})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCurrencyId = value);
                                final selectedCurrency = _currencies.firstWhere((c) => c.id == value);
                                widget.onInvoiceUpdate(
                                  widget.invoice.copyWith(currency: '${selectedCurrency.name} (${selectedCurrency.code})'),
                                );
                              }
                            },
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            border: Border.all(color: AppColors.grey200, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('جاري التحميل...'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ExpandableSection(
            title: 'خيارات إضافية',
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المخزن', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<WarehousesCubit, WarehousesState>(
                    builder: (context, state) {
                      if (state is WarehousesLoaded) {
                        _warehouses = state.warehouses;
                        if (_selectedWarehouseId == null && _warehouses.isNotEmpty) {
                          WarehouseEntity? mainWarehouse;
                          try {
                            mainWarehouse = _warehouses.firstWhere((w) => w.isMainStock == true);
                          } catch (e) {
                            mainWarehouse = _warehouses.first;
                          }
                          _selectedWarehouseId = mainWarehouse.id;
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: _selectedWarehouseId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _warehouses.map((warehouse) {
                            return DropdownMenuItem<int>(
                              value: warehouse.id,
                              child: Text(warehouse.name + (warehouse.isMainStock == true ? ' (الرئيسي)' : '')),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedWarehouseId = value);
                              final selectedWarehouse = _warehouses.firstWhere((w) => w.id == value);
                              widget.onInvoiceUpdate(
                                widget.invoice.copyWith(warehouse: selectedWarehouse.name),
                              );
                            }
                          },
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(width: AppSpacing.sm),
                            Text('جاري تحميل المخازن...'),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('ملاحظات', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'أضف ملاحظات...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      widget.onInvoiceUpdate(
                        widget.invoice.copyWith(notes: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'التالي: إضافة الأصناف',
            onPressed: widget.invoice.customer != null ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}

// lib/screens/sales_invoice/steps/step_2_items.dart

class Step2Items extends StatefulWidget {
  final Invoice invoice;
  final List<InvoiceItem> availableItems;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step2Items({
    Key? key,
    required this.invoice,
    required this.availableItems,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<Step2Items> createState() => _Step2ItemsState();
}

class _Step2ItemsState extends State<Step2Items> {
  final _searchController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addItem(InvoiceItem item) {
    final existingIndex = widget.invoice.items.indexWhere(
      (i) => i.id == item.id,
    );
    List<InvoiceItem> updatedItems;

    if (existingIndex >= 0) {
      updatedItems = List.from(widget.invoice.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
    } else {
      updatedItems = [...widget.invoice.items, item];
    }

    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
    _searchController.clear();
  }

  void _updateItemQuantity(int index, int delta) {
    final updatedItems = List<InvoiceItem>.from(widget.invoice.items);
    updatedItems[index] = updatedItems[index].copyWith(
      quantity: (updatedItems[index].quantity + delta).clamp(1, 999),
    );
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
  }

  void _removeItem(int index) {
    final updatedItems = List<InvoiceItem>.from(widget.invoice.items);
    updatedItems.removeAt(index);
    widget.onInvoiceUpdate(widget.invoice.copyWith(items: updatedItems));
  }

  void _simulateScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 1), () {
      final randomItem =
          widget.availableItems[DateTime.now().millisecond %
              widget.availableItems.length];
      _addItem(randomItem);
      setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.availableItems
        .where(
          (item) =>
              item.name.contains(_searchController.text) ||
              item.barcode.contains(_searchController.text),
        )
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صنف أو امسح الباركود...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isScanning ? AppColors.warning : AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _isScanning ? null : _simulateScan,
                  icon: Icon(
                    _isScanning ? Icons.hourglass_empty : Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_searchController.text.isNotEmpty && filteredItems.isNotEmpty)
          Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${NumberFormatter.formatCurrency(item.price)} | متوفر: ${item.stock}',
                  ),
                  onTap: () {
                    AddItemBottomSheet.show(
                      context,
                      item: item,
                      onAdd: _addItem,
                    );
                  },
                );
              },
            ),
          ),
        Expanded(
          child: widget.invoice.items.isEmpty
              ? const EmptyState(
                  emoji: '📦',
                  title: 'لم تتم إضافة أصناف بعد',
                  subtitle: 'ابحث أو امسح باركود لإضافة صنف',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ...List.generate(widget.invoice.items.length, (index) {
                        final item = widget.invoice.items[index];
                        return ItemCard(
                          item: item,
                          onIncrement: () => _updateItemQuantity(index, 1),
                          onDecrement: () => _updateItemQuantity(index, -1),
                          onDelete: () => _removeItem(index),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'المجموع الفرعي:',
                                  style: AppTextStyles.title,
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(
                                    widget.invoice.subtotal,
                                  ),
                                  style: AppTextStyles.title.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ExpandableSection(
                              title: 'خصومات ورسوم',
                              child: Column(
                                children: [
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            DropdownButtonFormField<
                                              DiscountType
                                            >(
                                              value:
                                                  widget.invoice.discount.type,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: DiscountType.amount,
                                                  child: Text('مبلغ'),
                                                ),
                                                DropdownMenuItem(
                                                  value: DiscountType.percent,
                                                  child: Text('نسبة %'),
                                                ),
                                              ],
                                              onChanged: (type) {
                                                if (type != null) {
                                                  widget.onInvoiceUpdate(
                                                    widget.invoice.copyWith(
                                                      discount: widget
                                                          .invoice
                                                          .discount
                                                          .copyWith(type: type),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'الخصم',
                                          ),
                                          onChanged: (value) {
                                            widget.onInvoiceUpdate(
                                              widget.invoice.copyWith(
                                                discount: widget
                                                    .invoice
                                                    .discount
                                                    .copyWith(
                                                      value:
                                                          double.tryParse(
                                                            value,
                                                          ) ??
                                                          0,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'رسوم أخرى',
                                    ),
                                    onChanged: (value) {
                                      widget.onInvoiceUpdate(
                                        widget.invoice.copyWith(
                                          otherCharges:
                                              double.tryParse(value) ?? 0,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (widget.invoice.discountAmount > 0 ||
                                widget.invoice.otherCharges > 0) ...[
                              const Divider(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'الإجمالي النهائي:',
                                    style: AppTextStyles.headline3,
                                  ),
                                  Text(
                                    NumberFormatter.formatCurrency(
                                      widget.invoice.total,
                                    ),
                                    style: AppTextStyles.headline3.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'رجوع',
                  onPressed: widget.onPrevious,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'التالي: الدفع',
                  onPressed: widget.invoice.items.isNotEmpty
                      ? widget.onNext
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// lib/screens/sales_invoice/steps/step_3_payment.dart

class Step3Payment extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Payment({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends State<Step3Payment> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.remaining.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0 && amount <= widget.invoice.remaining) {
      final updatedPayments = [
        ...widget.invoice.payments,
        Payment(method: _selectedMethod, amount: amount),
      ];
      widget.onInvoiceUpdate(
        widget.invoice.copyWith(payments: updatedPayments),
      );
      _amountController.text = widget.invoice.remaining.toStringAsFixed(0);
    }
  }

  void _removePayment(int index) {
    final updatedPayments = List<Payment>.from(widget.invoice.payments);
    updatedPayments.removeAt(index);
    widget.onInvoiceUpdate(widget.invoice.copyWith(payments: updatedPayments));
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.bank:
        return 'تحويل بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  String _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.bank:
        return '🏦';
      case PaymentMethod.deferred:
        return '📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'المبلغ الإجمالي',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        NumberFormatter.formatCurrency(widget.invoice.total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مدفوع',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatNumber(
                                  widget.invoice.paid,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'متبقي',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatNumber(
                                  widget.invoice.remaining,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Method Selection
                const Text('طريقة الدفع', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _selectedMethod = method),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _getPaymentMethodIcon(method),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getPaymentMethodLabel(method),
                                  style: AppTextStyles.small.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey700,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Form
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المبلغ', style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Method-specific fields
                      if (_selectedMethod == PaymentMethod.cash) ...[
                        const Text('الصندوق', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: 'الصندوق الرئيسي',
                          items: const [
                            DropdownMenuItem(
                              value: 'الصندوق الرئيسي',
                              child: Text('الصندوق الرئيسي'),
                            ),
                            DropdownMenuItem(
                              value: 'صندوق فرع الشمال',
                              child: Text('صندوق فرع الشمال'),
                            ),
                          ],
                          onChanged: (_) {},
                        ),
                      ],

                      if (_selectedMethod == PaymentMethod.bank) ...[
                        const Text('البنك', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: 'الراجحي',
                          items: const [
                            DropdownMenuItem(
                              value: 'الراجحي',
                              child: Text('الراجحي'),
                            ),
                            DropdownMenuItem(
                              value: 'الأهلي',
                              child: Text('الأهلي'),
                            ),
                            DropdownMenuItem(
                              value: 'الإنماء',
                              child: Text('الإنماء'),
                            ),
                          ],
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ExpandableSection(
                          title: 'تفاصيل التحويل',
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'رقم الحوالة',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'اسم المرسل',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_selectedMethod == PaymentMethod.deferred) ...[
                        const Text(
                          'تاريخ الاستحقاق',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: () async {
                            await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  DateTime.now()
                                      .add(const Duration(days: 30))
                                      .toString()
                                      .split(' ')[0],
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (widget.invoice.remaining > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إضافة دفعة (${NumberFormatter.formatCurrency(double.tryParse(_amountController.text) ?? 0)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Added Payments
                if (widget.invoice.payments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'الدفعات المضافة:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(widget.invoice.payments.length, (index) {
                    final payment = widget.invoice.payments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPaymentMethodLabel(payment.method),
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                NumberFormatter.formatCurrency(payment.amount),
                                style: AppTextStyles.small,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _removePayment(index),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.error,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                if (widget.invoice.remaining > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(color: AppColors.warning),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'فاتورة آجلة',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(widget.invoice.remaining)} سيتم إضافته كمديونية',
                                style: AppTextStyles.small,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'رجوع',
                  onPressed: widget.onPrevious,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'مراجعة وحفظ',
                  onPressed: widget.onNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// lib/screens/sales_invoice/steps/step_4_review.dart

class Step4Review extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPrevious;
  final VoidCallback onSave;
  final bool isQuotation;

  const Step4Review({
    Key? key,
    required this.invoice,
    required this.onPrevious,
    required this.onSave,
    this.isQuotation = false,
  }) : super(key: key);

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.bank:
        return 'تحويل بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'مراجعة الفاتورة',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'تأكد من صحة البيانات قبل الحفظ',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Invoice Details
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('رقم الفاتورة', invoice.number),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow('العميل', invoice.customer?.name ?? ''),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'التاريخ',
                        invoice.date.toString().split(' ')[0],
                      ),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'عدد الأصناف',
                        '${invoice.items.length} صنف',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'المجموع الفرعي',
                        NumberFormatter.formatCurrency(invoice.subtotal),
                      ),
                      if (invoice.discountAmount > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        _buildInfoRow(
                          'الخصم',
                          NumberFormatter.formatCurrency(
                            invoice.discountAmount,
                          ),
                          valueColor: AppColors.error,
                        ),
                      ],
                      if (invoice.otherCharges > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        _buildInfoRow(
                          'رسوم أخرى',
                          NumberFormatter.formatCurrency(invoice.otherCharges),
                          valueColor: AppColors.primary,
                        ),
                      ],
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'الإجمالي النهائي',
                        NumberFormatter.formatCurrency(invoice.total),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment Summary (hidden for quotations)
                if (!isQuotation)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    border: Border.all(color: AppColors.success),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملخص الدفع', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المدفوع', style: AppTextStyles.caption),
                          Text(
                            NumberFormatter.formatCurrency(invoice.paid),
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المتبقي', style: AppTextStyles.caption),
                          Text(
                            NumberFormatter.formatCurrency(invoice.remaining),
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (invoice.payments.isNotEmpty) ...[
                        const Divider(height: AppSpacing.lg),
                        ...invoice.payments.map((payment) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getPaymentMethodLabel(payment.method),
                                  style: AppTextStyles.small,
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(
                                    payment.amount,
                                  ),
                                  style: AppTextStyles.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),

                if (!isQuotation && 
                    invoice.remaining > 0 && 
                    invoice.payments.any((p) => p.method == PaymentMethod.deferred)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(color: AppColors.warning),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'فاتورة آجلة',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(invoice.remaining)} سيتم إضافته كمديونية على حساب العميل',
                                style: AppTextStyles.small,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(text: 'رجوع', onPressed: onPrevious),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'حفظ الفاتورة',
                  icon: const Icon(Icons.check, size: 24),
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHighlight ? AppTextStyles.title : AppTextStyles.caption,
        ),
        Text(
          value,
          style: isHighlight
              ? AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )
              : AppTextStyles.bodyMedium.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
