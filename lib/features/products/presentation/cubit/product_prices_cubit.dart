import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/products/domain/entities/product_price_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_price_repository.dart';

// States
abstract class ProductPricesState {}

class ProductPricesInitial extends ProductPricesState {}

class ProductPricesLoading extends ProductPricesState {}

class ProductPricesLoaded extends ProductPricesState {
  final List<ProductPriceEntity> prices;
  final int? selectedSubUnitId;

  ProductPricesLoaded({required this.prices, this.selectedSubUnitId});
}

class ProductPricesSaving extends ProductPricesState {}

class ProductPricesSaved extends ProductPricesState {
  final String message;

  ProductPricesSaved({required this.message});
}

class ProductPricesError extends ProductPricesState {
  final String message;

  ProductPricesError({required this.message});
}

// Cubit
class ProductPricesCubit extends Cubit<ProductPricesState> {
  final ProductPriceRepository repository;

  ProductPricesCubit(this.repository) : super(ProductPricesInitial());

  Future<void> loadAllPrices() async {
    emit(ProductPricesLoading());
    
    final result = await repository.getAllPrices();
    
    result.fold(
      (failure) => emit(ProductPricesError(message: failure.message)),
      (prices) => emit(ProductPricesLoaded(prices: prices)),
    );
  }

  Future<void> loadPricesBySubUnit(int subUnitId) async {
    emit(ProductPricesLoading());
    
    final result = await repository.getPricesBySubUnit(subUnitId);
    
    result.fold(
      (failure) => emit(ProductPricesError(message: failure.message)),
      (prices) => emit(ProductPricesLoaded(prices: prices, selectedSubUnitId: subUnitId)),
    );
  }

  Future<void> savePrice({
    required int subUnitId,
    required int priceLevel,
    required double amount,
    double? localAmount,
    String? currencyCode,
    double? exchangeRate,
    int? currencyId,
    double minQuantity = 1.0,
  }) async {
    emit(ProductPricesSaving());
    
    final price = ProductPriceEntity(
      categorySubUnitId: subUnitId,
      priceLevel: priceLevel,
      bidAmount: amount,
      bidLocalAmount: localAmount ?? amount,
      bidCurrencyCode: currencyCode ?? 'SAR',
      bidExchangeRate: exchangeRate ?? 1.0,
      bidCurrencyId: currencyId,
      minQuantity: minQuantity,
    );
    
    final result = await repository.savePrice(price);
    
    result.fold(
      (failure) => emit(ProductPricesError(message: failure.message)),
      (id) {
        emit(ProductPricesSaved(message: 'تم حفظ السعر بنجاح'));
        // Reload prices
        loadAllPrices();
      },
    );
  }

  Future<void> deletePrice(int id) async {
    final result = await repository.deletePrice(id);
    
    result.fold(
      (failure) => emit(ProductPricesError(message: failure.message)),
      (_) {
        emit(ProductPricesSaved(message: 'تم حذف السعر بنجاح'));
        loadAllPrices();
      },
    );
  }
}
