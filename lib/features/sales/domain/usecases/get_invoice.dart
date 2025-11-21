import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class GetInvoice implements Usecase<Either<Failure, InvoiceEntity>, int> {
  final InvoiceRepository repository;
  GetInvoice(this.repository);

  @override
  Future<Either<Failure, InvoiceEntity>> call({required int params}) async {
    return await repository.getInvoice(params);
  }
}
