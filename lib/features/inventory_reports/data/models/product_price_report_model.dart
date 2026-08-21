import 'package:muhasib/features/inventory_reports/domain/entities/product_price_report_entity.dart';

class ProductPriceReportModel extends ProductPriceReportEntity {
  const ProductPriceReportModel({
    required super.productId,
    required super.productName,
    required super.barcodeNo,
    required super.unitName,
    required super.retailPrice,
    required super.wholesalePrice,
    required super.minPrice,
  });

  factory ProductPriceReportModel.fromMap(Map<String, dynamic> map) {
    return ProductPriceReportModel(
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'غير معروف',
      barcodeNo: map['barcode_no'] as String? ?? '',
      unitName: map['unit_name'] as String? ?? 'حبة',
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      minPrice: (map['min_price'] as num?)?.toDouble() ?? 0,
    );
  }

  ProductPriceReportEntity toEntity() => this;
}
