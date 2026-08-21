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
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearchQuery = false,
  }) {
    return ReportFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      accountId: accountId ?? this.accountId,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilter &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          accountId == other.accountId &&
          customerId == other.customerId &&
          supplierId == other.supplierId &&
          productId == other.productId &&
          warehouseId == other.warehouseId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        accountId,
        customerId,
        supplierId,
        productId,
        warehouseId,
        searchQuery,
      );

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

