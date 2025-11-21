import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class DeleteInvoice implements Usecase<Either<Failure, void>, int> {
  final InvoiceRepository repository;
  DeleteInvoice(this.repository);

  @override
  Future<Either<Failure, void>> call({required int params}) async {
    return await repository.deleteInvoice(params);
  }
}
