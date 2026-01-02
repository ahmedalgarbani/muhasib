import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

/// Create a sales return invoice.
///
/// NOTE: Accounting posting (journal entries + balances + limits) is handled
/// atomically inside `InvoiceLocalDataSource` when the return invoice is saved.

class CreateReturnInvoice extends Usecase<Either<Failure, int>, CreateReturnParams> {
  final InvoiceRepository repository;

  CreateReturnInvoice(
    this.repository,
  );

  @override
  Future<Either<Failure, int>> call({
    required CreateReturnParams params,
  }) async {
    // Create Return Invoice (posting is handled in the datasource).
    final result = await repository.createReturnInvoice(
      params.returnInvoice,
      params.parentInvoiceId,
    );

    return result;
  }
}

class CreateReturnParams extends Equatable {
  final InvoiceEntity returnInvoice;
  final int parentInvoiceId;
  final String customerName;

  const CreateReturnParams({
    required this.returnInvoice,
    required this.parentInvoiceId,
    required this.customerName,
  });

  @override
  List<Object?> get props => [returnInvoice, parentInvoiceId, customerName];
}
