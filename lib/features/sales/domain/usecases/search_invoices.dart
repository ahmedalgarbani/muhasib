import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class SearchInvoices
    implements Usecase<Either<Failure, List<InvoiceEntity>>, String> {
  final InvoiceRepository repository;
  SearchInvoices(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({
    required String params,
  }) async {
    return await repository.searchInvoices(params);
  }
}
