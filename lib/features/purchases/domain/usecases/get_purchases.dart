import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecases/usecase.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';

class GetPurchases extends UseCase<List<InvoiceEntity>, NoParams> {
  final PurchaseRepository repository;

  GetPurchases(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({required NoParams params}) async {
    return await repository.getPurchaseInvoices();
  }
}
