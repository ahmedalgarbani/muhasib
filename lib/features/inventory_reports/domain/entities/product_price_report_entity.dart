import 'package:equatable/equatable.dart';

/// كيان سعر صنف للطباعة
class ProductPriceReportEntity extends Equatable {
  final int productId;
  final String productName;
  final String barcodeNo;
  final String unitName;
  final double retailPrice; // سعر البيع (sell_amount)
  final double wholesalePrice; // سعر الجملة (price_level 2)
  final double minPrice; // أدنى سعر (price_level 3 أو 4)

  const ProductPriceReportEntity({
    required this.productId,
    required this.productName,
    required this.barcodeNo,
    required this.unitName,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.minPrice,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        barcodeNo,
        unitName,
        retailPrice,
        wholesalePrice,
        minPrice,
      ];
}
