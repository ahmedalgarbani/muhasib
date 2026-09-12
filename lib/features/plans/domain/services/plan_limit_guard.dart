import '../entities/plan_limit.dart';
import 'plan_cache.dart';

/// Small helper used by data-domain cubits to enforce plan caps.
class PlanLimitGuard {
  PlanLimitGuard._();

  /// Returns `null` when another record is allowed, otherwise an Arabic
  /// message that can be surfaced directly in the UI.
  static String? check(PlanLimit limit, int currentCount) {
    if (PlanCache.canAdd(limit, currentCount)) return null;
    final max = PlanCache.limitOf(limit);
    return 'وصلت إلى الحد الأقصى لعدد ${limit.labelAr} في الخطة '
        '${PlanCache.plan.nameAr} ($max). قم بالترقية من شاشة الخطط للمتابعة.';
  }

  /// Message shown when a feature itself is not part of the active plan.
  static String featureLocked(String featureLabelAr) {
    return '$featureLabelAr غير متاحة في الخطة ${PlanCache.plan.nameAr}. '
        'قم بالترقية للمتابعة.';
  }
}
