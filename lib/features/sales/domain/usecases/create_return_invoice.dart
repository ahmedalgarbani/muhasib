import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Create a sales return invoice
/// 
/// This use case:
/// 1. Creates a return invoice linked to the original sales invoice
/// 2. Generates reverse accounting entries (debit customer, credit sales returns)
/// 3. Updates inventory quantities (increases stock)
/// 4. Updates customer balance (reduces accounts receivable)
class CreateReturnInvoice extends Usecase<Either<Failure, int>, CreateReturnParams> {
  final InvoiceRepository repository;

  CreateReturnInvoice(this.repository);

  @override
  Future<Either<Failure, int>> call({
    required CreateReturnParams params,
  }) async {
    return await repository.createReturnInvoice(
      params.returnInvoice,
      params.parentInvoiceId,
    );
  }
}

class CreateReturnParams extends Equatable {
  final InvoiceEntity returnInvoice;
  final int parentInvoiceId;

  const CreateReturnParams({
    required this.returnInvoice,
    required this.parentInvoiceId,
  });

  @override
  List<Object?> get props => [returnInvoice, parentInvoiceId];
}
