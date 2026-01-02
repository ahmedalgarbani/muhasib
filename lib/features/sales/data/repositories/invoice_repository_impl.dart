import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource localDataSource;
  final JournalRepository? journalRepository;
  final AccountConfigService? accountConfigService;

  InvoiceRepositoryImpl(
    this.localDataSource, {
    this.journalRepository,
    this.accountConfigService,
  });

  /// Generate unique journal entry number
  String _generateJournalNumber(String prefix) {
    return '$prefix-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
  }

  /// Create journal entry for sales invoice
  /// Debit: Customer/Cash | Credit: Sales + Tax
  Future<void> _createSalesJournalEntry(InvoiceEntity invoice) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    final amount = invoice.amount ?? 0.0;
    final taxAmount = invoice.taxAmt ?? 0.0;
    final discountAmount = invoice.discountAmt ?? 0.0;
    final netAmount = amount + taxAmount - discountAmount;
    
    if (netAmount <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    int lineNumber = 1;
    
    // Debit: Customer (receivable)
    lines.add(JournalEntryLineModel(
      lineNumber: lineNumber++,
      accountId: config.customersAccountId,
      accountName: 'العملاء',
      currencyCode: 'SAR',
      debit: netAmount,
      credit: 0,
    ));
    
    // Debit: Discount Allowed (if applicable)
    if (discountAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.discountAllowedAccountId,
        accountName: 'خصم مسموح به',
        currencyCode: 'SAR',
        debit: discountAmount,
        credit: 0,
      ));
    }
    
    // Credit: Sales
    if (amount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.salesAccountId,
        accountName: 'المبيعات',
        currencyCode: 'SAR',
        debit: 0,
        credit: amount,
      ));
    }
    
    // Credit: Tax (if applicable)
    if (taxAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.taxAccountId,
        accountName: 'ضريبة القيمة المضافة',
        currencyCode: 'SAR',
        debit: 0,
        credit: taxAmount,
      ));
    }
    
    final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('SI'),
      entryDate: DateTime.now(),
      description: 'فاتورة مبيعات رقم ${invoice.number}',
      referenceNumber: invoice.number,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
  }

  /// Create reversing journal entry for deleted/returned invoice
  Future<void> _createReversingJournalEntry(InvoiceEntity invoice, String description) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    final amount = invoice.amount ?? 0.0;
    final taxAmount = invoice.taxAmt ?? 0.0;
    final discountAmount = invoice.discountAmt ?? 0.0;
    final netAmount = amount + taxAmount - discountAmount;
    
    if (netAmount <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    int lineNumber = 1;
    
    // Credit: Customer (reverse debit)
    lines.add(JournalEntryLineModel(
      lineNumber: lineNumber++,
      accountId: config.customersAccountId,
      accountName: 'العملاء',
      currencyCode: 'SAR',
      debit: 0,
      credit: netAmount,
    ));
    
    // Credit: Discount Allowed (reverse debit if applicable)
    if (discountAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.discountAllowedAccountId,
        accountName: 'خصم مسموح به',
        currencyCode: 'SAR',
        debit: 0,
        credit: discountAmount,
      ));
    }
    
    // Debit: Sales (reverse credit)
    if (amount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.salesAccountId,
        accountName: 'المبيعات',
        currencyCode: 'SAR',
        debit: amount,
        credit: 0,
      ));
    }
    
    // Debit: Tax (reverse credit if applicable)
    if (taxAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.taxAccountId,
        accountName: 'ضريبة القيمة المضافة',
        currencyCode: 'SAR',
        debit: taxAmount,
        credit: 0,
      ));
    }
    
    final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('SR'),
      entryDate: DateTime.now(),
      description: description,
      referenceNumber: invoice.number,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
  }

  /// Create journal entry for sales return
  /// Debit: Sales Returns + Tax | Credit: Customer
  Future<void> _createSalesReturnJournalEntry(InvoiceEntity returnInvoice) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    final amount = returnInvoice.amount ?? 0.0;
    final taxAmount = returnInvoice.taxAmt ?? 0.0;
    final netAmount = amount + taxAmount;
    
    if (netAmount <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    int lineNumber = 1;
    
    // Debit: Sales Returns
    if (amount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.salesReturnsAccountId,
        accountName: 'مردودات المبيعات',
        currencyCode: 'SAR',
        debit: amount,
        credit: 0,
      ));
    }
    
    // Debit: Tax
    if (taxAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.taxAccountId,
        accountName: 'ضريبة القيمة المضافة',
        currencyCode: 'SAR',
        debit: taxAmount,
        credit: 0,
      ));
    }
    
    // Credit: Customer
    lines.add(JournalEntryLineModel(
      lineNumber: lineNumber++,
      accountId: config.customersAccountId,
      accountName: 'العملاء',
      currencyCode: 'SAR',
      debit: 0,
      credit: netAmount,
    ));
    
    final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('SRT'),
      entryDate: DateTime.now(),
      description: 'مرتجع مبيعات رقم ${returnInvoice.number}',
      referenceNumber: returnInvoice.number,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
  }

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
      final model = invoice is InvoiceModel
          ? invoice
          : InvoiceModel.fromEntity(invoice);
      final id = await localDataSource.insertInvoice(model);
      
      // Create journal entry for sales invoices only (not quotations)
      if (invoice.invoiceType == InvoiceType.salesInvoice.value) {
        await _createSalesJournalEntry(invoice.copyWith(id: id));
      }
      
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
      // Get old invoice for reversing entry
      InvoiceEntity? oldInvoice;
      if (invoice.id != null && invoice.invoiceType == InvoiceType.salesInvoice.value) {
        try {
          oldInvoice = await localDataSource.getInvoice(invoice.id!);
        } catch (_) {}
      }
      
      final model = invoice is InvoiceModel
          ? invoice
          : InvoiceModel.fromEntity(invoice);
      await localDataSource.updateInvoice(model);
      
      // Reverse old entry and create new one for sales invoices
      if (invoice.invoiceType == InvoiceType.salesInvoice.value) {
        if (oldInvoice != null) {
          await _createReversingJournalEntry(
            oldInvoice,
            'قيد عكسي - تعديل فاتورة مبيعات ${invoice.number}',
          );
        }
        await _createSalesJournalEntry(invoice);
      }
      
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
      // Get invoice before deletion for reversing entry
      InvoiceEntity? invoiceToDelete;
      try {
        invoiceToDelete = await localDataSource.getInvoice(id);
      } catch (_) {}
      
      await localDataSource.deleteInvoice(id);
      
      // Create reversing entry for sales invoices
      if (invoiceToDelete != null && 
          invoiceToDelete.invoiceType == InvoiceType.salesInvoice.value) {
        await _createReversingJournalEntry(
          invoiceToDelete,
          'قيد عكسي - حذف فاتورة مبيعات ${invoiceToDelete.number}',
        );
      }
      
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
      
      // Create journal entry for the new sales invoice
      await _createSalesJournalEntry(salesInvoice.copyWith(id: id));
      
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
      
      // Create journal entry for sales return
      await _createSalesReturnJournalEntry(returnInvoice.copyWith(id: id));
      
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
}

/// Extension for invoice copyWith
extension InvoiceEntityCopyWith on InvoiceEntity {
  InvoiceEntity copyWith({int? id}) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceType: invoiceType,
      invoiceTransType: invoiceTransType,
      number: number,
      date: date,
      customerId: customerId,
      stockId: stockId,
      amount: amount,
      totalAmount: totalAmount,
      finalAmt: finalAmt,
      taxAmt: taxAmt,
      discountAmt: discountAmt,
      statement: statement,
      lines: lines,
      paymentStatus: paymentStatus,
      dueDate: dueDate,
      shippingAddress: shippingAddress,
      parentInvoiceId: parentInvoiceId,
      quotationStatus: quotationStatus,
    );
  }
}

