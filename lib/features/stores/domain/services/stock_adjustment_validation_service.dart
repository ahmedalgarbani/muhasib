import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';

/// Service to validate stock adjustments and prevent fraud/manipulation
abstract class StockAdjustmentValidationService {
  /// Validates that an adjustment meets all requirements
  Future<Either<Failure, bool>> validateAdjustment(StockAdjustmentEntity adjustment);
  
  /// Checks if adjustment exceeds daily limits
  Future<Either<Failure, AdjustmentLimitResult>> checkDailyLimit({
    required int warehouseId,
    required double adjustmentValue,
  });
  
  /// Checks if user has permission for this adjustment amount
  Future<Either<Failure, bool>> hasAdjustmentPermission({
    required int? userId,
    required double amount,
  });
}

class AdjustmentLimitResult {
  final bool exceeds;
  final double dailyLimit;
  final double usedToday;
  final double remaining;
  
  const AdjustmentLimitResult({
    required this.exceeds,
    required this.dailyLimit,
    required this.usedToday,
    required this.remaining,
  });
}

class AdjustmentValidationRules {
  /// Maximum adjustment value that doesn't require approval
  static const double autoApprovalLimit = 10000.0;
  
  /// Maximum daily adjustment value per warehouse
  static const double dailyLimit = 50000.0;
  
  /// Reasons that are considered high-risk and require extra scrutiny
  static const List<String> highRiskReasons = ['theft', 'loss', 'error'];
  
  /// Required fields for a valid adjustment
  static List<String> validate(StockAdjustmentEntity adjustment) {
    final errors = <String>[];
    
    // Reason is required
    if (adjustment.settlementReason == null || adjustment.settlementReason!.isEmpty) {
      errors.add('سبب التسوية مطلوب');
    }
    
    // Statement/notes required for high-value adjustments
    if ((adjustment.totalAmount ?? 0) > autoApprovalLimit && adjustment.statement.isEmpty) {
      errors.add('الملاحظات مطلوبة للتسويات التي تتجاوز ${autoApprovalLimit.toInt()} ريال');
    }
    
    // Must have warehouse
    if (adjustment.stockId == null) {
      errors.add('يجب تحديد المخزن');
    }
    
    // Must have at least one line
    if (adjustment.lines.isEmpty) {
      errors.add('يجب إضافة صنف واحد على الأقل');
    }
    
    // Each line must have a reason for decrease (theft, damage, etc.)
    for (var i = 0; i < adjustment.lines.length; i++) {
      final line = adjustment.lines[i];
      if (line.reason == null || line.reason!.isEmpty) {
        errors.add('سبب التسوية مطلوب للصنف رقم ${i + 1}');
      }
      if (line.quantity <= 0) {
        errors.add('الكمية يجب أن تكون أكبر من صفر للصنف رقم ${i + 1}');
      }
    }
    
    return errors;
  }
  
  /// Determines if this adjustment requires approval
  static bool requiresApproval(StockAdjustmentEntity adjustment) {
    final totalValue = adjustment.totalAmount ?? 0;
    
    // High value adjustments need approval
    if (totalValue > autoApprovalLimit) {
      return true;
    }
    
    // High-risk reasons need approval
    if (highRiskReasons.contains(adjustment.settlementReason)) {
      return true;
    }
    
    return false;
  }
}
