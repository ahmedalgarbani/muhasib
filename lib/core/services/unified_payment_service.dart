import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/database/tables/unified_payments_table.dart';
import 'package:sqflite/sqflite.dart';

/// Comprehensive service for managing all payment operations
/// Handles receipts, payments, allocations, and reconciliation
class UnifiedPaymentService {
  final DatabaseService _databaseService;

  UnifiedPaymentService(this._databaseService);

  // Table names
  static const String _paymentsTable = 'unified_payments';
  static const String _allocationsTable = 'payment_allocations';
  static const String _methodTypesTable = 'payment_method_types';
  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalLinesTable = 'journal_entry_lines';
  static const String _accountsTable = 'accounts';

  /// Get all payment method types
  Future<Either<Failure, List<PaymentMethodTypeModel>>> getPaymentMethodTypes({
    bool activeOnly = true,
  }) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        _methodTypesTable,
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'sort_order',
      );
      
      return Right(result.map((e) => PaymentMethodTypeModel.fromMap(e)).toList());
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب طرق الدفع: ${e.toString()}'));
    }
  }

  /// Create a new payment
  Future<Either<Failure, PaymentResult>> createPayment({
    required CreatePaymentRequest request,
    bool createJournalEntry = true,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Generate payment number
        final paymentNumber = await _generatePaymentNumber(txn, request.documentType);
        
        // Calculate local amount
        final localAmount = request.amount * request.exchangeRate;
        
        // Insert payment
        final paymentId = await txn.insert(_paymentsTable, {
          'payment_number': paymentNumber,
          'document_type': request.documentType,
          'document_id': request.documentId,
          'document_number': request.documentNumber,
          'payment_method_type_id': request.paymentMethodTypeId,
          'party_type': request.partyType,
          'party_id': request.partyId,
          'party_name': request.partyName,
          'payment_date': request.paymentDate.millisecondsSinceEpoch ~/ 1000,
          'due_date': request.dueDate?.millisecondsSinceEpoch != null
              ? request.dueDate!.millisecondsSinceEpoch ~/ 1000
              : null,
          'amount': request.amount,
          'currency_id': request.currencyId,
          'currency_code': request.currencyCode,
          'exchange_rate': request.exchangeRate,
          'local_amount': localAmount,
          'from_account_id': request.fromAccountId,
          'to_account_id': request.toAccountId,
          'bank_id': request.bankId,
          'bank_account_number': request.bankAccountNumber,
          'check_number': request.checkNumber,
          'check_date': request.checkDate?.millisecondsSinceEpoch != null
              ? request.checkDate!.millisecondsSinceEpoch ~/ 1000
              : null,
          'check_holder_name': request.checkHolderName,
          'card_type': request.cardType,
          'card_last_four': request.cardLastFour,
          'transaction_reference': request.transactionReference,
          'authorization_code': request.authorizationCode,
          'transfer_reference': request.transferReference,
          'sender_name': request.senderName,
          'receiver_name': request.receiverName,
          'transfer_bank': request.transferBank,
          'commission_amount': request.commissionAmount,
          'commission_account_id': request.commissionAccountId,
          'status': request.status,
          'notes': request.notes,
          'creation_time': now,
          'last_modification_time': now,
        });
        
        // Create journal entry if requested
        int? journalEntryId;
        if (createJournalEntry && request.fromAccountId != null && request.toAccountId != null) {
          journalEntryId = await _createPaymentJournalEntry(
            txn: txn,
            paymentId: paymentId,
            paymentNumber: paymentNumber,
            request: request,
            localAmount: localAmount,
            now: now,
          );
          
          // Update payment with journal entry ID
          await txn.update(
            _paymentsTable,
            {'journal_entry_id': journalEntryId},
            where: 'id = ?',
            whereArgs: [paymentId],
          );
        }
        
        // Auto-allocate if document specified
        if (request.autoAllocate && request.documentId > 0) {
          await _allocatePayment(
            txn: txn,
            paymentId: paymentId,
            targetDocumentType: request.documentType,
            targetDocumentId: request.documentId,
            targetDocumentNumber: request.documentNumber,
            amount: request.amount,
            currencyId: request.currencyId,
            exchangeRate: request.exchangeRate,
            localAmount: localAmount,
          );
        }
        
        return Right(PaymentResult(
          paymentId: paymentId,
          paymentNumber: paymentNumber,
          journalEntryId: journalEntryId,
          amount: request.amount,
          localAmount: localAmount,
        ));
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إنشاء الدفعة: ${e.toString()}'));
    }
  }

  /// Allocate a payment to one or more documents
  Future<Either<Failure, int>> allocatePaymentToDocument({
    required int paymentId,
    required String targetDocumentType,
    required int targetDocumentId,
    String? targetDocumentNumber,
    required double amount,
    double discountAmount = 0.0,
    int? discountAccountId,
    double writeOffAmount = 0.0,
    int? writeOffAccountId,
    String? notes,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        // Get payment details
        final payment = await txn.query(
          _paymentsTable,
          where: 'id = ?',
          whereArgs: [paymentId],
          limit: 1,
        );
        
        if (payment.isEmpty) {
          return Left(NotFoundFailure('الدفعة غير موجودة'));
        }
        
        final paymentData = payment.first;
        final unallocated = (paymentData['amount'] as num).toDouble() - 
                           (paymentData['allocated_amount'] as num).toDouble();
        
        if (amount > unallocated + 0.01) {
          return Left(ValidationFailure(message: 'المبلغ المطلوب تخصيصه أكبر من المتاح'));
        }
        
        final currencyId = paymentData['currency_id'] as int?;
        final exchangeRate = (paymentData['exchange_rate'] as num?)?.toDouble() ?? 1.0;
        final localAmount = amount * exchangeRate;
        
        final allocationId = await _allocatePayment(
          txn: txn,
          paymentId: paymentId,
          targetDocumentType: targetDocumentType,
          targetDocumentId: targetDocumentId,
          targetDocumentNumber: targetDocumentNumber,
          amount: amount,
          currencyId: currencyId,
          exchangeRate: exchangeRate,
          localAmount: localAmount,
          discountAmount: discountAmount,
          discountAccountId: discountAccountId,
          writeOffAmount: writeOffAmount,
          writeOffAccountId: writeOffAccountId,
          notes: notes,
        );
        
        return Right(allocationId);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في تخصيص الدفعة: ${e.toString()}'));
    }
  }

  /// Get payments for a document
  Future<Either<Failure, List<Map<String, dynamic>>>> getPaymentsForDocument({
    required String documentType,
    required int documentId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.rawQuery('''
        SELECT p.*, pmt.name_ar as payment_method_name, pmt.code as payment_method_code
        FROM $_paymentsTable p
        LEFT JOIN $_methodTypesTable pmt ON p.payment_method_type_id = pmt.id
        WHERE p.document_type = ? AND p.document_id = ? AND p.is_deleted = 0
        ORDER BY p.payment_date DESC
      ''', [documentType, documentId]);
      
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب الدفعات: ${e.toString()}'));
    }
  }

  /// Get payment allocations
  Future<Either<Failure, List<Map<String, dynamic>>>> getPaymentAllocations(int paymentId) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.query(
        _allocationsTable,
        where: 'payment_id = ?',
        whereArgs: [paymentId],
        orderBy: 'creation_time DESC',
      );
      
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب التخصيصات: ${e.toString()}'));
    }
  }

  /// Cancel a payment
  Future<Either<Failure, void>> cancelPayment(int paymentId, {String? reason}) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Get payment
        final payment = await txn.query(
          _paymentsTable,
          where: 'id = ?',
          whereArgs: [paymentId],
          limit: 1,
        );
        
        if (payment.isEmpty) {
          return Left(NotFoundFailure('الدفعة غير موجودة'));
        }
        
        final paymentData = payment.first;
        final currentStatus = paymentData['status'] as int;
        
        if (currentStatus == PaymentStatus.cancelled) {
          return Left(ValidationFailure(message: 'الدفعة ملغية مسبقاً'));
        }
        
        // Update payment status
        await txn.update(
          _paymentsTable,
          {
            'status': PaymentStatus.cancelled,
            'notes': reason != null 
                ? '${paymentData['notes'] ?? ''}\nسبب الإلغاء: $reason' 
                : paymentData['notes'],
            'last_modification_time': now,
          },
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        
        // Delete allocations
        await txn.delete(
          _allocationsTable,
          where: 'payment_id = ?',
          whereArgs: [paymentId],
        );
        
        // Create reversing journal entry if exists
        final journalEntryId = paymentData['journal_entry_id'] as int?;
        if (journalEntryId != null) {
          await _createReversingJournalEntry(txn, journalEntryId, now);
        }
        
        return const Right(null);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في إلغاء الدفعة: ${e.toString()}'));
    }
  }

  /// Mark check as bounced
  Future<Either<Failure, void>> markCheckBounced(int paymentId, {
    String? reason,
    double? bounceFee,
    int? bounceAccountId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      return await db.transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Get payment
        final payment = await txn.query(
          _paymentsTable,
          where: 'id = ?',
          whereArgs: [paymentId],
          limit: 1,
        );
        
        if (payment.isEmpty) {
          return Left(NotFoundFailure('الدفعة غير موجودة'));
        }
        
        // Update status
        await txn.update(
          _paymentsTable,
          {
            'status': PaymentStatus.bounced,
            'notes': reason != null 
                ? 'شيك مرتجع: $reason' 
                : 'شيك مرتجع',
            'last_modification_time': now,
          },
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        
        // Create reversing entry and bounce fee entry
        final journalEntryId = payment.first['journal_entry_id'] as int?;
        if (journalEntryId != null) {
          await _createReversingJournalEntry(txn, journalEntryId, now);
        }
        
        return const Right(null);
      });
    } catch (e) {
      return Left(UnknownFailure('فشل في تسجيل ارتجاع الشيك: ${e.toString()}'));
    }
  }

  /// Get unallocated payments for a party
  Future<Either<Failure, List<Map<String, dynamic>>>> getUnallocatedPayments({
    required String partyType,
    required int partyId,
  }) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.rawQuery('''
        SELECT p.*, pmt.name_ar as payment_method_name
        FROM $_paymentsTable p
        LEFT JOIN $_methodTypesTable pmt ON p.payment_method_type_id = pmt.id
        WHERE p.party_type = ? AND p.party_id = ? 
          AND p.status = 1 AND p.is_deleted = 0
          AND p.amount > p.allocated_amount
        ORDER BY p.payment_date
      ''', [partyType, partyId]);
      
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب الدفعات غير المخصصة: ${e.toString()}'));
    }
  }

  // ==================== Private Helper Methods ====================

  Future<String> _generatePaymentNumber(Transaction txn, String documentType) async {
    String prefix;
    switch (documentType) {
      case PaymentDocumentType.salesInvoice:
      case PaymentDocumentType.receiptVoucher:
        prefix = 'REC';
        break;
      case PaymentDocumentType.purchaseInvoice:
      case PaymentDocumentType.paymentVoucher:
        prefix = 'PAY';
        break;
      case PaymentDocumentType.salesReturn:
        prefix = 'REF';
        break;
      default:
        prefix = 'PMT';
    }
    
    final result = await txn.rawQuery(
      "SELECT COALESCE(MAX(CAST(SUBSTR(payment_number, 5) AS INTEGER)), 0) + 1 as next "
      "FROM unified_payments WHERE payment_number LIKE '$prefix-%'",
    );
    
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  Future<int> _createPaymentJournalEntry({
    required Transaction txn,
    required int paymentId,
    required String paymentNumber,
    required CreatePaymentRequest request,
    required double localAmount,
    required int now,
  }) async {
    // Get account info
    final fromMeta = await _getAccountMeta(txn, request.fromAccountId!);
    final toMeta = await _getAccountMeta(txn, request.toAccountId!);
    
    final description = request.documentType == PaymentDocumentType.salesInvoice ||
                       request.documentType == PaymentDocumentType.receiptVoucher
        ? 'سند قبض - ${request.documentNumber ?? paymentNumber}'
        : 'سند صرف - ${request.documentNumber ?? paymentNumber}';
    
    // Generate journal number
    final journalNumber = await _nextJournalNumber(txn, 'PMT');
    
    // Insert journal entry
    final journalEntryId = await txn.insert(_journalEntriesTable, {
      'number': journalNumber,
      'entry_date': now,
      'description': description,
      'reference_type': 'payment',
      'reference_id': paymentId,
      'reference_number': paymentNumber,
      'status': 1,
      'is_posted': 1,
      'total_debit': localAmount,
      'total_credit': localAmount,
      'difference': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });
    
    // Debit line
    await txn.insert(_journalLinesTable, {
      'journal_entry_id': journalEntryId,
      'line_number': 1,
      'account_id': request.toAccountId,
      'account_code': toMeta['code'],
      'account_name': toMeta['name'],
      'currency_id': request.currencyId,
      'debit_amount': localAmount,
      'credit_amount': 0.0,
      'description': description,
    });
    
    // Credit line
    await txn.insert(_journalLinesTable, {
      'journal_entry_id': journalEntryId,
      'line_number': 2,
      'account_id': request.fromAccountId,
      'account_code': fromMeta['code'],
      'account_name': fromMeta['name'],
      'currency_id': request.currencyId,
      'debit_amount': 0.0,
      'credit_amount': localAmount,
      'description': description,
    });
    
    // Update account balances
    await txn.rawUpdate(
      'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
      [localAmount, request.toAccountId],
    );
    await txn.rawUpdate(
      'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) - ? WHERE id = ?',
      [localAmount, request.fromAccountId],
    );
    
    // Handle commission if any
    if (request.commissionAmount != null && request.commissionAmount! > 0 && request.commissionAccountId != null) {
      await txn.insert(_journalLinesTable, {
        'journal_entry_id': journalEntryId,
        'line_number': 3,
        'account_id': request.commissionAccountId,
        'debit_amount': request.commissionAmount,
        'credit_amount': 0.0,
        'description': 'رسوم تحويل/عمولة',
      });
    }
    
    return journalEntryId;
  }

  Future<int> _allocatePayment({
    required Transaction txn,
    required int paymentId,
    required String targetDocumentType,
    required int targetDocumentId,
    String? targetDocumentNumber,
    required double amount,
    int? currencyId,
    required double exchangeRate,
    required double localAmount,
    double discountAmount = 0.0,
    int? discountAccountId,
    double writeOffAmount = 0.0,
    int? writeOffAccountId,
    String? notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Insert allocation
    final allocationId = await txn.insert(_allocationsTable, {
      'payment_id': paymentId,
      'target_document_type': targetDocumentType,
      'target_document_id': targetDocumentId,
      'target_document_number': targetDocumentNumber,
      'allocated_amount': amount,
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'local_amount': localAmount,
      'discount_amount': discountAmount,
      'discount_account_id': discountAccountId,
      'write_off_amount': writeOffAmount,
      'write_off_account_id': writeOffAccountId,
      'notes': notes,
      'creation_time': now,
    });
    
    // Update payment allocated amount
    await txn.rawUpdate(
      'UPDATE $_paymentsTable SET allocated_amount = allocated_amount + ?, last_modification_time = ? WHERE id = ?',
      [amount, now, paymentId],
    );
    
    return allocationId;
  }

  Future<void> _createReversingJournalEntry(Transaction txn, int originalJournalId, int now) async {
    // Get original entry
    final original = await txn.query(
      _journalEntriesTable,
      where: 'id = ?',
      whereArgs: [originalJournalId],
      limit: 1,
    );
    
    if (original.isEmpty) return;
    
    final originalData = original.first;
    final originalNumber = originalData['number'] as String;
    
    // Create reversing entry
    final reverseNumber = await _nextJournalNumber(txn, 'REV');
    
    final reverseEntryId = await txn.insert(_journalEntriesTable, {
      'number': reverseNumber,
      'entry_date': now,
      'description': 'قيد عكسي - $originalNumber',
      'reference_type': 'reversal',
      'reference_id': originalJournalId,
      'reference_number': originalNumber,
      'status': 1,
      'is_posted': 1,
      'total_debit': originalData['total_credit'],
      'total_credit': originalData['total_debit'],
      'difference': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });
    
    // Get and reverse lines
    final lines = await txn.query(
      _journalLinesTable,
      where: 'journal_entry_id = ?',
      whereArgs: [originalJournalId],
    );
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final accountId = line['account_id'] as int;
      final originalDebit = (line['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final originalCredit = (line['credit_amount'] as num?)?.toDouble() ?? 0.0;
      
      // Reverse: swap debit and credit
      await txn.insert(_journalLinesTable, {
        'journal_entry_id': reverseEntryId,
        'line_number': i + 1,
        'account_id': accountId,
        'account_code': line['account_code'],
        'account_name': line['account_name'],
        'currency_id': line['currency_id'],
        'debit_amount': originalCredit,
        'credit_amount': originalDebit,
        'description': 'عكس: ${line['description'] ?? ''}',
      });
      
      // Reverse balance impact
      await txn.rawUpdate(
        'UPDATE $_accountsTable SET balance = COALESCE(balance, 0) + ? WHERE id = ?',
        [originalCredit - originalDebit, accountId],
      );
    }
  }

  Future<Map<String, dynamic>> _getAccountMeta(Transaction txn, int accountId) async {
    final result = await txn.query(
      _accountsTable,
      columns: ['code', 'name'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return {'code': result.first['code'] ?? '', 'name': result.first['name'] ?? ''};
    }
    return {'code': '', 'name': ''};
  }

  Future<String> _nextJournalNumber(Transaction txn, String prefix) async {
    final result = await txn.rawQuery(
      "SELECT COALESCE(MAX(CAST(SUBSTR(number, ${prefix.length + 2}) AS INTEGER)), 0) + 1 as next "
      "FROM journal_entries WHERE number LIKE '$prefix-%'",
    );
    final next = (result.first['next'] as int?) ?? 1;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }
}

// ==================== Models ====================

/// Payment method type model
class PaymentMethodTypeModel {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;
  final int? defaultAccountId;
  final bool requiresBank;
  final bool requiresReference;
  final bool requiresDueDate;
  final bool isImmediate;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isActive;

  PaymentMethodTypeModel({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    this.defaultAccountId,
    required this.requiresBank,
    required this.requiresReference,
    required this.requiresDueDate,
    required this.isImmediate,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.isActive,
  });

  factory PaymentMethodTypeModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodTypeModel(
      id: map['id'] as int,
      code: map['code'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      defaultAccountId: map['default_account_id'] as int?,
      requiresBank: (map['requires_bank'] as int) == 1,
      requiresReference: (map['requires_reference'] as int) == 1,
      requiresDueDate: (map['requires_due_date'] as int) == 1,
      isImmediate: (map['is_immediate'] as int) == 1,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      sortOrder: map['sort_order'] as int,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}

/// Request model for creating a payment
class CreatePaymentRequest {
  final String documentType;
  final int documentId;
  final String? documentNumber;
  final int paymentMethodTypeId;
  final String? partyType;
  final int? partyId;
  final String? partyName;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final double amount;
  final int? currencyId;
  final String? currencyCode;
  final double exchangeRate;
  final int? fromAccountId;
  final int? toAccountId;
  final int? bankId;
  final String? bankAccountNumber;
  final String? checkNumber;
  final DateTime? checkDate;
  final String? checkHolderName;
  final String? cardType;
  final String? cardLastFour;
  final String? transactionReference;
  final String? authorizationCode;
  final String? transferReference;
  final String? senderName;
  final String? receiverName;
  final String? transferBank;
  final double? commissionAmount;
  final int? commissionAccountId;
  final int status;
  final String? notes;
  final bool autoAllocate;

  CreatePaymentRequest({
    required this.documentType,
    required this.documentId,
    this.documentNumber,
    required this.paymentMethodTypeId,
    this.partyType,
    this.partyId,
    this.partyName,
    required this.paymentDate,
    this.dueDate,
    required this.amount,
    this.currencyId,
    this.currencyCode,
    this.exchangeRate = 1.0,
    this.fromAccountId,
    this.toAccountId,
    this.bankId,
    this.bankAccountNumber,
    this.checkNumber,
    this.checkDate,
    this.checkHolderName,
    this.cardType,
    this.cardLastFour,
    this.transactionReference,
    this.authorizationCode,
    this.transferReference,
    this.senderName,
    this.receiverName,
    this.transferBank,
    this.commissionAmount,
    this.commissionAccountId,
    this.status = PaymentStatus.completed,
    this.notes,
    this.autoAllocate = true,
  });
}

/// Result of payment creation
class PaymentResult {
  final int paymentId;
  final String paymentNumber;
  final int? journalEntryId;
  final double amount;
  final double localAmount;

  PaymentResult({
    required this.paymentId,
    required this.paymentNumber,
    this.journalEntryId,
    required this.amount,
    required this.localAmount,
  });
}
