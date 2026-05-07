import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_line_model.dart';
import 'package:muhasib/features/accounts/data/models/journal_entry_model.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/models/invoice_model.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource localDataSource;
  final JournalRepository? journalRepository;
  final AccountConfigService? accountConfigService;
  final NumberSequenceService? numberSequenceService;

  InvoiceRepositoryImpl({
    required this.localDataSource,
    this.journalRepository,
    this.accountConfigService,
    this.numberSequenceService,
  });

  /// Generate unique journal entry number
  String _generateJournalNumber(String prefix) {
    return '$prefix-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
  }

  /// Create journal entry for sales invoice
  /// القيد المحاسبي الصحيح:
  /// - نقدي: من ح/ الصندوق، إلى ح/ المبيعات + الضريبة
  /// - آجل: من ح/ العملاء، إلى ح/ المبيعات + الضريبة
  /// - الخصم يُطرح من المبيعات قبل حساب الضريبة
  Future<void> _createSalesJournalEntry(InvoiceEntity invoice) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    
    // الحساب الصحيح محاسبياً:
    // 1. المبلغ الأصلي (قبل الخصم)
    final originalAmount = invoice.amount;
    
    // 2. الخصم (يُطرح من المبلغ الأصلي)
    final discountAmount = invoice.discountAmt ?? 0.0;
    
    // 3. المبلغ بعد الخصم (هذا ما يُسجل كمبيعات)
    final amountAfterDiscount = originalAmount - discountAmount;
    
    // 4. الضريبة (تُحسب على المبلغ بعد الخصم)
    final taxAmount = invoice.taxAmt ?? 0.0;
    
    // 5. المبلغ الإجمالي المستحق (بعد الخصم + الضريبة)
    final totalDueAmount = amountAfterDiscount + taxAmount;
    
    if (totalDueAmount <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    int lineNumber = 1;
    final isCash = invoice.invoiceTransType == 0; // 0 = نقدي، 1 = آجل
    
    // مدين: الصندوق (نقدي) أو العملاء (آجل)
    lines.add(JournalEntryLineModel(
      lineNumber: lineNumber++,
      accountId: isCash ? config.cashAccountId : config.customersAccountId,
      accountName: isCash ? 'الصندوق' : 'العملاء',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: totalDueAmount,
      credit: 0,
    ));
    
    // دائن: المبيعات (المبلغ بعد الخصم)
    if (amountAfterDiscount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.salesAccountId,
        accountName: 'المبيعات',
        currencyCode: invoice.currencyCode ?? 'YER',
        debit: 0,
        credit: amountAfterDiscount,
      ));
    }
    
    // دائن: ضريبة القيمة المضافة - مخرجات
    if (taxAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.taxAccountId,
        accountName: 'ضريبة القيمة المضافة - مخرجات',
        currencyCode: invoice.currencyCode ?? 'YER',
        debit: 0,
        credit: taxAmount,
      ));
    }
    
    final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);
    
    // التحقق من التوازن المحاسبي
    final difference = (totalDebit - totalCredit).abs();
    if (difference >= 0.01) {
      throw Exception(
        'خطأ محاسبي: القيد غير متوازن! المدين: $totalDebit، الدائن: $totalCredit، الفرق: $difference'
      );
    }
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('SI'),
      entryDate: DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000),
      description: 'فاتورة مبيعات ${isCash ? "نقدية" : "آجلة"} رقم ${invoice.number}',
      referenceNumber: invoice.number,
      referenceId: invoice.id,
      referenceType: 'sales_invoice',
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
    
    // قيد تكلفة البضاعة المباعة (COGS)
    await _createCOGSEntry(invoice);
  }

  /// Create reversing journal entry for deleted/returned invoice
  /// عكس القيد الأصلي بالكامل
  Future<void> _createReversingJournalEntry(InvoiceEntity invoice, String description) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    
    // نفس الحسابات من القيد الأصلي
    final originalAmount = invoice.amount;
    final discountAmount = invoice.discountAmt ?? 0.0;
    final amountAfterDiscount = originalAmount - discountAmount;
    final taxAmount = invoice.taxAmt ?? 0.0;
    final totalDueAmount = amountAfterDiscount + taxAmount;
    
    if (totalDueAmount <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    int lineNumber = 1;
    final isCash = invoice.invoiceTransType == 0;
    
    // دائن: الصندوق/العملاء (عكس المدين)
    lines.add(JournalEntryLineModel(
      lineNumber: lineNumber++,
      accountId: isCash ? config.cashAccountId : config.customersAccountId,
      accountName: isCash ? 'الصندوق' : 'العملاء',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: 0,
      credit: totalDueAmount,
    ));
    
    // مدين: المبيعات (عكس الدائن)
    if (amountAfterDiscount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.salesAccountId,
        accountName: 'المبيعات',
        currencyCode: invoice.currencyCode ?? 'YER',
        debit: amountAfterDiscount,
        credit: 0,
      ));
    }
    
    // مدين: الضريبة (عكس الدائن)
    if (taxAmount > 0) {
      lines.add(JournalEntryLineModel(
        lineNumber: lineNumber++,
        accountId: config.taxAccountId,
        accountName: 'ضريبة القيمة المضافة - مخرجات',
        currencyCode: invoice.currencyCode ?? 'YER',
        debit: taxAmount,
        credit: 0,
      ));
    }
    
    final totalDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('SR'),
      entryDate: DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000),
      description: description,
      referenceNumber: invoice.number,
      referenceId: invoice.id,
      referenceType: 'sales_reversal',
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
    
    // عكس قيد تكلفة البضاعة المباعة
    await _reverseCOGSEntry(invoice);
  }

  /// قيد تكلفة البضاعة المباعة (COGS Entry)
  /// مدين: تكلفة البضاعة المباعة
  /// دائن: المخزون
  Future<void> _createCOGSEntry(InvoiceEntity invoice) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    
    // حساب التكلفة الإجمالية من بنود الفاتورة
    double totalCost = 0.0;
    for (final line in invoice.lines) {
      final costPrice = line.costPrice ?? 0.0;
      final quantity = line.quantity ?? 0.0;
      totalCost += costPrice * quantity;
    }
    
    if (totalCost <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    
    // مدين: تكلفة البضاعة المباعة
    lines.add(JournalEntryLineModel(
      lineNumber: 1,
      accountId: config.costOfGoodsSoldAccountId,
      accountName: 'تكلفة البضاعة المباعة',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: totalCost,
      credit: 0,
    ));
    
    // دائن: المخزون
    lines.add(JournalEntryLineModel(
      lineNumber: 2,
      accountId: config.inventoryAccountId,
      accountName: 'المخزون',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: 0,
      credit: totalCost,
    ));
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('COGS'),
      entryDate: DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000),
      description: 'تكلفة البضاعة المباعة - فاتورة ${invoice.number}',
      referenceNumber: invoice.number,
      referenceId: invoice.id,
      referenceType: 'cogs_entry',
      totalDebit: totalCost,
      totalCredit: totalCost,
      difference: 0,
      lines: lines,
    );
    
    await journalRepository!.createJournalEntry(journalEntry);
  }

  /// عكس قيد تكلفة البضاعة المباعة
  /// مدين: المخزون
  /// دائن: تكلفة البضاعة المباعة
  Future<void> _reverseCOGSEntry(InvoiceEntity invoice) async {
    if (journalRepository == null || accountConfigService == null) return;
    
    final config = await accountConfigService!.getSalesAccountConfig();
    
    // حساب التكلفة الإجمالية
    double totalCost = 0.0;
    for (final line in invoice.lines) {
      final costPrice = line.costPrice ?? 0.0;
      final quantity = line.quantity ?? 0.0;
      totalCost += costPrice * quantity;
    }
    
    if (totalCost <= 0) return;
    
    final lines = <JournalEntryLineModel>[];
    
    // مدين: المخزون (عكس الدائن)
    lines.add(JournalEntryLineModel(
      lineNumber: 1,
      accountId: config.inventoryAccountId,
      accountName: 'المخزون',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: totalCost,
      credit: 0,
    ));
    
    // دائن: تكلفة البضاعة المباعة (عكس المدين)
    lines.add(JournalEntryLineModel(
      lineNumber: 2,
      accountId: config.costOfGoodsSoldAccountId,
      accountName: 'تكلفة البضاعة المباعة',
      currencyCode: invoice.currencyCode ?? 'YER',
      debit: 0,
      credit: totalCost,
    ));
    
    final journalEntry = JournalEntryModel(
      number: _generateJournalNumber('COGSR'),
      entryDate: DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000),
      description: 'عكس تكلفة البضاعة - فاتورة ${invoice.number}',
      referenceNumber: invoice.number,
      referenceId: invoice.id,
      referenceType: 'cogs_reversal',
      totalDebit: totalCost,
      totalCredit: totalCost,
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
      
      // Note: Journal entry is already created by insertInvoice() in localDataSource
      // No need to create it again here to avoid double balance update
      
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

extension InvoiceEntityExtension on InvoiceEntity {
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

