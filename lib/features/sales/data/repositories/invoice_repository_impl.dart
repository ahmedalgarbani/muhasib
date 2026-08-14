import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource localDataSource;
  final NumberSequenceService? numberSequenceService;

  InvoiceRepositoryImpl({
    required this.localDataSource,
    this.numberSequenceService,
  });

  // Note: All accounting journal entries, stock updates, and their
  // reversals are handled inside InvoiceLocalDataSourceImpl transactions.
  // This repository only delegates persistence.

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices() async {
    try {
      final items = await localDataSource.getInvoices();
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoice(int id) async {
    try {
      final item = await localDataSource.getInvoice(id);
      return Right(item.toEntity());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createInvoice(InvoiceEntity invoice) async {
    try {
      // Generate unique invoice number if not provided
      String invoiceNumber = invoice.number;
      if (invoiceNumber.isEmpty && numberSequenceService != null) {
        final sequenceType = _getSequenceType(invoice.invoiceType);
        invoiceNumber = await numberSequenceService!.getNextNumber(sequenceType);
      }

      // Create invoice with generated number
      final invoiceWithNumber = invoice.copyWith(number: invoiceNumber);

      final model = invoiceWithNumber is InvoiceModel
          ? invoiceWithNumber
          : InvoiceModel.fromEntity(invoiceWithNumber);

      final id = await localDataSource.insertInvoice(model);

      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvoice(InvoiceEntity invoice) async {
    try {
      final model = invoice is InvoiceModel
          ? invoice
          : InvoiceModel.fromEntity(invoice);
      await localDataSource.updateInvoice(model);

      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(int id) async {
    try {
      await localDataSource.deleteInvoice(id);

      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> searchInvoices(
    String query,
  ) async {
    try {
      final items = await localDataSource.searchInvoices(query);
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoicesByType(
    int invoiceType,
  ) async {
    try {
      final items = await localDataSource.getInvoicesByType(invoiceType);
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getQuotations() async {
    try {
      final items = await localDataSource.getQuotations();
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getOpenQuotations() async {
    try {
      final items = await localDataSource.getOpenQuotations();
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> convertQuotationToInvoice(
    int quotationId,
    InvoiceEntity salesInvoice,
  ) async {
    try {
      final model = salesInvoice is InvoiceModel
          ? salesInvoice
          : InvoiceModel.fromEntity(salesInvoice);
      final id = await localDataSource.convertQuotationToInvoice(
        quotationId,
        model,
      );

      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getReturnInvoices() async {
    try {
      final items = await localDataSource.getReturnInvoices();
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getReturnsByParentInvoice(
    int parentInvoiceId,
  ) async {
    try {
      final items = await localDataSource.getReturnsByParentInvoice(
        parentInvoiceId,
      );
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> createReturnInvoice(
    InvoiceEntity returnInvoice,
    int parentInvoiceId,
  ) async {
    try {
      final model = returnInvoice is InvoiceModel
          ? returnInvoice
          : InvoiceModel.fromEntity(returnInvoice);
      final id = await localDataSource.createReturnInvoice(
        model,
        parentInvoiceId,
      );

      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoicesByCustomer(
    int customerId,
  ) async {
    try {
      final items = await localDataSource.getInvoicesByCustomer(customerId);
      return Right(items.map((e) => e.toEntity()).toList());
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Get sequence type based on invoice type
  String _getSequenceType(int invoiceType) {
    switch (invoiceType) {
      case 1: return 'sales_invoice';
      case 2: return 'purchase_invoice';
      case 4: return 'quotation';
      case 5: return 'sales_return';
      case 6: return 'purchase_return';
      default: return 'sales_invoice';
    }
  }
}
