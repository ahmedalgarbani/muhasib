class ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? accountId;
  final int? customerId;
  final int? supplierId;
  final int? productId;
  final int? warehouseId;
  final String? searchQuery;

  const ReportFilter({
    this.startDate,
    this.endDate,
    this.accountId,
    this.customerId,
    this.supplierId,
    this.productId,
    this.warehouseId,
    this.searchQuery,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    int? customerId,
    int? supplierId,
    int? productId,
    int? warehouseId,
    String? searchQuery,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Default filter for current month
  factory ReportFilter.currentMonth() {
    final now = DateTime.now();
    return ReportFilter(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
    );
  }

  // Filter for current year
  factory ReportFilter.currentYear() {
    final now = DateTime.now();
    return ReportFilter(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31, 23, 59, 59, 999),
    );
  }
}

