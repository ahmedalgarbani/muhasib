import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecases/usecase.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';

class CreatePurchase extends UseCase<int, InvoiceEntity> {
  final PurchaseRepository repository;

  CreatePurchase(this.repository);

  @override
  Future<Either<Failure, int>> call({required InvoiceEntity params}) async {
    return await repository.createPurchaseInvoice(params);
  }
}
