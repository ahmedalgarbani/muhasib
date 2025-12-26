class SalesSummaryEntity {
  final double totalSales;
  final double totalReturns;
  final double totalDiscounts;
  final double totalTaxes;
  final double netSales;
  final int invoiceCount;
  final int returnCount;
  final int customerCount;
  final List<TopProductEntity> topProducts;
  final List<TopCustomerEntity> topCustomers;
  final Map<String, double> dailySales;

  const SalesSummaryEntity({
    required this.totalSales,
    required this.totalReturns,
    required this.totalDiscounts,
    required this.totalTaxes,
    required this.netSales,
    required this.invoiceCount,
    required this.returnCount,
    required this.customerCount,
    required this.topProducts,
    required this.topCustomers,
    required this.dailySales,
  });

  double get averageInvoiceValue => invoiceCount > 0 ? netSales / invoiceCount : 0;
}

class TopProductEntity {
  final int productId;
  final String productName;
  final double quantity;
  final double totalAmount;
  final int salesCount;

  const TopProductEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.salesCount,
  });
}

class TopCustomerEntity {
  final int customerId;
  final String customerName;
  final double totalPurchases;
  final int invoiceCount;

  const TopCustomerEntity({
    required this.customerId,
    required this.customerName,
    required this.totalPurchases,
    required this.invoiceCount,
  });
}
