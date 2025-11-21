import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Get all quotations (invoice_type = 3)
class GetQuotations extends Usecase<Either<Failure, List<InvoiceEntity>>, NoParams> {
  final InvoiceRepository repository;

  GetQuotations(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({
    required NoParams params,
  }) async {
    return await repository.getQuotations();
  }
}
