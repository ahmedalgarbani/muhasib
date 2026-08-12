import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Service for protecting quotations from tampering
/// Provides: locking, validation, expiry checking, and audit trail
class QuotationProtectionService {
  final DatabaseService _databaseService;

  QuotationProtectionService(this._databaseService);

  static const String _invoicesTable = 'invoices';
  static const String _invoiceLinesTable = 'invoice_lines';
  static const String _auditLogsTable = 'audit_logs';

  // Quotation approval statuses
  static const int statusDraft = 0;
  static const int statusPendingApproval = 1;
  static const int statusApproved = 2;
  static const int statusRejected = 3;
  static const int statusExpired = 4;
  static const int statusConverted = 5;

  /// Check if a quotation can be edited
  Future<Either<Failure, bool>> canEditQuotation(int quotationId) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.query(
        _invoicesTable,
        columns: ['invoice_type', 'is_locked', 'next_invoice_id', 'approval_status', 'valid_until'],
        where: 'id = ?',
        whereArgs: [quotationId],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return Left(NotFoundFailure('عرض السعر غير موجود'));
      }
      
      final quotation = result.first;
      
      // Check if it's a quotation
      if ((quotation['invoice_type'] as int?) != 3) {
        return Left(ValidationFailure(message: 'هذا ليس عرض سعر'));
      }
      
      // Check if locked
      if ((quotation['is_locked'] as int?) == 1) {
        return Left(ValidationFailure(message: 'عرض السعر مقفل ولا يمكن تعديله'));
      }
      
      // Check if already converted
      final nextInvoiceId = quotation['next_invoice_id'] as int?;
      if (nextInvoiceId != null && nextInvoiceId > 0) {
        return Left(ValidationFailure(message: 'عرض السعر محول لفاتورة ولا يمكن تعديله'));
      }
      
      // Check approval status
      final approvalStatus = (quotation['approval_status'] as int?) ?? 0;
      if (approvalStatus == statusApproved) {
        return Left(ValidationFailure(message: 'عرض السعر معتمد ولا يمكن تعديله'));
      }
      
      // Check expiry
      final validUntil = quotation['valid_until'] as int?;
      if (validUntil != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > validUntil) {
          return Left(ValidationFailure(message: 'عرض السعر منتهي الصلاحية'));
        }
      }
      
      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure('فشل في التحقق: ${e.toString()}'));
    }
  }

  /// Check if a quotation can be deleted
  Future<Either<Failure, bool>> canDeleteQuotation(int quotationId) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.query(
        _invoicesTable,
        columns: ['invoice_type', 'is_locked', 'next_invoice_id', 'approval_status'],
        where: 'id = ?',
        whereArgs: [quotationId],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return Left(NotFoundFailure('عرض السعر غير موجود'));
      }
      
      final quotation = result.first;
      
      // Check if it's a quotation
      if ((quotation['invoice_type'] as int?) != 3) {
        return Left(ValidationFailure(message: 'هذا ليس عرض سعر'));
      }
      
      // Check if already converted - CANNOT delete
      final nextInvoiceId = quotation['next_invoice_id'] as int?;
      if (nextInvoiceId != null && nextInvoiceId > 0) {
        return Left(ValidationFailure(message: 'لا يمكن حذف عرض سعر محول لفاتورة'));
      }
      
      // Check if approved - CANNOT delete
      final approvalStatus = (quotation['approval_status'] as int?) ?? 0;
      if (approvalStatus == statusApproved) {
        return Left(ValidationFailure(message: 'لا يمكن حذف عرض سعر معتمد'));
      }
      
      // Check if locked
      if ((quotation['is_locked'] as int?) == 1) {
        return Left(ValidationFailure(message: 'عرض السعر مقفل ولا يمكن حذفه'));
      }
      
      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure('فشل في التحقق: ${e.toString()}'));
    }
  }

  /// Check if a quotation can be converted to invoice
  Future<Either<Failure, QuotationConversionCheck>> canConvertQuotation(int quotationId) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.query(
        _invoicesTable,
        where: 'id = ?',
        whereArgs: [quotationId],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return Left(NotFoundFailure('عرض السعر غير موجود'));
      }
      
      final quotation = result.first;
      final warnings = <String>[];
      
      // Check if it's a quotation
      if ((quotation['invoice_type'] as int?) != 3) {
        return Left(ValidationFailure(message: 'هذا ليس عرض سعر'));
      }
      
      // Check if already converted
      final nextInvoiceId = quotation['next_invoice_id'] as int?;
      if (nextInvoiceId != null && nextInvoiceId > 0) {
        return Left(ValidationFailure(message: 'عرض السعر محول مسبقاً'));
      }
      
      // Check expiry - warning but allow
      final validUntil = quotation['valid_until'] as int?;
      if (validUntil != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > validUntil) {
          warnings.add('عرض السعر منتهي الصلاحية');
        }
      }
      
      // Check approval status
      final approvalStatus = (quotation['approval_status'] as int?) ?? 0;
      if (approvalStatus == statusRejected) {
        warnings.add('عرض السعر مرفوض');
      }
      
      // Verify data integrity using hash
      final originalHash = quotation['original_hash'] as String?;
      if (originalHash != null) {
        final currentHash = await _calculateQuotationHash(quotationId);
        if (currentHash != originalHash) {
          warnings.add('⚠️ تم اكتشاف تغييرات على البيانات الأصلية');
        }
      }
      
      return Right(QuotationConversionCheck(
        canConvert: true,
        warnings: warnings,
        quotationData: quotation,
      ));
    } catch (e) {
      return Left(UnknownFailure('فشل في التحقق: ${e.toString()}'));
    }
  }

  /// Lock a quotation to prevent further edits
  Future<Either<Failure, void>> lockQuotation({
    required int quotationId,
    required int lockedBy,
    String? reason,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Calculate and store hash
      final hash = await _calculateQuotationHash(quotationId);
      
      await db.update(
        _invoicesTable,
        {
          'is_locked': 1,
          'locked_at': now,
          'locked_by': lockedBy,
          'locked_reason': reason ?? 'تم القفل للحماية',
          'original_hash': hash,
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      
      // Log the action
      await _logAction(db, quotationId, 'LOCK', lockedBy, reason);
      
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('فشل في قفل العرض: ${e.toString()}'));
    }
  }

  /// Unlock a quotation (admin only)
  Future<Either<Failure, void>> unlockQuotation({
    required int quotationId,
    required int unlockedBy,
    String? reason,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // First check if already converted
      final result = await db.query(
        _invoicesTable,
        columns: ['next_invoice_id'],
        where: 'id = ?',
        whereArgs: [quotationId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final nextInvoiceId = result.first['next_invoice_id'] as int?;
        if (nextInvoiceId != null && nextInvoiceId > 0) {
          return Left(ValidationFailure(message: 'لا يمكن فتح قفل عرض سعر محول'));
        }
      }
      
      await db.update(
        _invoicesTable,
        {
          'is_locked': 0,
          'locked_at': null,
          'locked_by': null,
          'locked_reason': null,
          'version': db.rawQuery(
            'SELECT version FROM $_invoicesTable WHERE id = ?',
            [quotationId],
          ).then((r) => ((r.first['version'] as int?) ?? 0) + 1),
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      
      // Log the action
      await _logAction(db, quotationId, 'UNLOCK', unlockedBy, reason);
      
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('فشل في فتح قفل العرض: ${e.toString()}'));
    }
  }

  /// Set quotation validity period
  Future<Either<Failure, void>> setQuotationValidity({
    required int quotationId,
    required DateTime validUntil,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await db.update(
        _invoicesTable,
        {
          'valid_until': validUntil.millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('فشل في تحديث الصلاحية: ${e.toString()}'));
    }
  }

  /// Approve a quotation
  Future<Either<Failure, void>> approveQuotation({
    required int quotationId,
    required int approvedBy,
    String? notes,
    bool autoLock = true,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Calculate hash before approval
      final hash = await _calculateQuotationHash(quotationId);
      
      await db.update(
        _invoicesTable,
        {
          'approval_status': statusApproved,
          'approved_at': now,
          'approved_by': approvedBy,
          'approval_notes': notes,
          'is_locked': autoLock ? 1 : 0,
          'locked_at': autoLock ? now : null,
          'locked_by': autoLock ? approvedBy : null,
          'locked_reason': autoLock ? 'تم القفل تلقائياً عند الاعتماد' : null,
          'original_hash': hash,
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      
      // Log the action
      await _logAction(db, quotationId, 'APPROVE', approvedBy, notes);
      
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('فشل في اعتماد العرض: ${e.toString()}'));
    }
  }

  /// Reject a quotation
  Future<Either<Failure, void>> rejectQuotation({
    required int quotationId,
    required int rejectedBy,
    required String reason,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await db.update(
        _invoicesTable,
        {
          'approval_status': statusRejected,
          'approved_at': now,
          'approved_by': rejectedBy,
          'approval_notes': 'مرفوض: $reason',
          'is_locked': 1,
          'locked_at': now,
          'locked_by': rejectedBy,
          'locked_reason': 'مرفوض: $reason',
          'last_modification_time': now,
        },
        where: 'id = ?',
        whereArgs: [quotationId],
      );
      
      // Log the action
      await _logAction(db, quotationId, 'REJECT', rejectedBy, reason);
      
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('فشل في رفض العرض: ${e.toString()}'));
    }
  }

  /// Get expired quotations
  Future<Either<Failure, List<Map<String, dynamic>>>> getExpiredQuotations() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final result = await db.query(
        _invoicesTable,
        where: 'invoice_type = 3 AND valid_until IS NOT NULL AND valid_until < ? AND next_invoice_id IS NULL',
        whereArgs: [now],
        orderBy: 'valid_until DESC',
      );
      
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure('فشل في جلب العروض المنتهية: ${e.toString()}'));
    }
  }

  /// Mark expired quotations
  Future<Either<Failure, int>> markExpiredQuotations() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final count = await db.rawUpdate('''
        UPDATE $_invoicesTable 
        SET approval_status = ?, 
            is_locked = 1, 
            locked_reason = 'منتهي الصلاحية',
            last_modification_time = ?
        WHERE invoice_type = 3 
          AND valid_until IS NOT NULL 
          AND valid_until < ? 
          AND next_invoice_id IS NULL
          AND approval_status != ?
      ''', [statusExpired, now, now, statusExpired]);
      
      return Right(count);
    } catch (e) {
      return Left(UnknownFailure('فشل في تحديث العروض المنتهية: ${e.toString()}'));
    }
  }

  /// Calculate hash of quotation data for integrity check
  Future<String> _calculateQuotationHash(int quotationId) async {
    final db = await _databaseService.database;
    
    // Get quotation data
    final quotation = await db.query(
      _invoicesTable,
      where: 'id = ?',
      whereArgs: [quotationId],
      limit: 1,
    );
    
    if (quotation.isEmpty) return '';
    
    // Get lines data
    final lines = await db.query(
      _invoiceLinesTable,
      where: 'invoice_id = ?',
      whereArgs: [quotationId],
      orderBy: 'id ASC',
    );
    
    // Build data string for hashing
    final q = quotation.first;
    final dataToHash = {
      'amount': q['amount'],
      'final_amt': q['final_amt'],
      'tax_amt': q['tax_amt'],
      'discount_amt': q['discount_amt'],
      'customer_id': q['customer_id'],
      'stock_id': q['stock_id'],
      'lines': lines.map((l) => {
        'product_id': l['category_id'],
        'quantity': l['quantity'],
        'price': l['price'],
        'total': l['total_price'],
      }).toList(),
    };
    
    final jsonStr = json.encode(dataToHash);
    final bytes = utf8.encode(jsonStr);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Log an action for audit trail
  Future<void> _logAction(
    Database db,
    int quotationId,
    String action,
    int userId,
    String? notes,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await db.insert(_auditLogsTable, {
      'entity_type': 'quotation',
      'entity_id': quotationId,
      'action': action,
      'user_id': userId,
      'description': notes,
      'created_at': now,
    });
  }
}

/// Result of conversion check
class QuotationConversionCheck {
  final bool canConvert;
  final List<String> warnings;
  final Map<String, dynamic> quotationData;

  QuotationConversionCheck({
    required this.canConvert,
    required this.warnings,
    required this.quotationData,
  });
  
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Approval status enum for display
class QuotationApprovalStatus {
  static const int draft = 0;
  static const int pendingApproval = 1;
  static const int approved = 2;
  static const int rejected = 3;
  static const int expired = 4;
  static const int converted = 5;

  static String getName(int status) {
    switch (status) {
      case draft: return 'مسودة';
      case pendingApproval: return 'قيد الاعتماد';
      case approved: return 'معتمد';
      case rejected: return 'مرفوض';
      case expired: return 'منتهي الصلاحية';
      case converted: return 'محول لفاتورة';
      default: return 'غير محدد';
    }
  }

  static String getColor(int status) {
    switch (status) {
      case draft: return '#6B7280';
      case pendingApproval: return '#F59E0B';
      case approved: return '#10B981';
      case rejected: return '#EF4444';
      case expired: return '#9CA3AF';
      case converted: return '#8B5CF6';
      default: return '#6B7280';
    }
  }
}
