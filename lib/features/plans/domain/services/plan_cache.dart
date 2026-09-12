import '../entities/license_entity.dart';
import '../entities/plan_entity.dart';
import '../entities/plan_feature.dart';
import '../entities/plan_limit.dart';
import '../plans_catalog.dart';

/// In-memory snapshot of the active plan, refreshed by `PlansCubit`.
/// Lets data/domain code (cubits, services) check entitlements without a
/// BuildContext — mirrors the existing `SettingsCache` pattern.
class PlanCache {
  PlanCache._();

  static PlanEntity _plan = PlansCatalog.free;
  static LicenseEntity? _license;
  static bool _expired = false;

  static void update({
    required PlanEntity plan,
    LicenseEntity? license,
    bool expired = false,
  }) {
    _plan = plan;
    _license = license;
    _expired = expired;
  }

  static void reset() => update(plan: PlansCatalog.free, license: null);

  static PlanEntity get plan => _plan;

  static LicenseEntity? get license => _license;

  static bool get isTrial => (_license?.isTrial ?? false) && !_expired;

  static bool get isExpired => _expired;

  static bool isEnabled(PlanFeature feature) => _plan.hasFeature(feature);

  static int? limitOf(PlanLimit limit) => _plan.limitOf(limit);

  static bool isUnlimited(PlanLimit limit) => _plan.isUnlimited(limit);

  static bool canAdd(PlanLimit limit, int currentCount) {
    final max = limitOf(limit);
    return max == null || currentCount < max;
  }
}
