import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/plans/domain/entities/license_entity.dart';
import 'package:muhasib/features/plans/domain/entities/plan_entity.dart';
import 'package:muhasib/features/plans/domain/entities/plan_feature.dart';
import 'package:muhasib/features/plans/domain/entities/plan_limit.dart';
import 'package:muhasib/features/plans/domain/entities/plan_tier.dart';
import 'package:muhasib/features/plans/domain/plans_catalog.dart';
import 'package:muhasib/features/plans/domain/repositories/plan_repository.dart';
import 'package:muhasib/features/plans/domain/services/device_identity_service.dart';
import 'package:muhasib/features/plans/domain/services/license_key_service.dart';
import 'package:muhasib/features/plans/domain/services/plan_cache.dart';
import 'plans_state.dart';

/// Owns the active subscription: loads the stored license, starts a 14-day
/// device-bound trial on first run, validates user-entered keys and keeps
/// [PlanCache] in sync so any layer can gate on entitlements.
///
/// The stored key is re-validated against this device on every startup, so a
/// copied database/license file cannot unlock a paid plan on another device.
class PlansCubit extends Cubit<PlansState> {
  final IPlanRepository repository;
  final DeviceIdentityService deviceIdentity;

  PlanEntity _plan = PlansCatalog.free;
  LicenseEntity? _license;
  bool _expired = false;
  String? _deviceId;

  PlansCubit({required this.repository, required this.deviceIdentity})
      : super(const PlansInitial());

  PlanEntity get plan => _plan;

  LicenseEntity? get license => _license;

  bool get isExpired => _expired;

  bool get isTrial => (_license?.isTrial ?? false) && !_expired;

  /// Identifier bound into the license key. Available after [load].
  String? get deviceId => _deviceId;

  bool hasFeature(PlanFeature feature) => !_expired && _plan.hasFeature(feature);

  int? limitOf(PlanLimit limit) =>
      _expired ? PlansCatalog.free.limitOf(limit) : _plan.limitOf(limit);

  @override
  void emit(PlansState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<String> resolveDeviceId() async {
    final existing = _deviceId;
    if (existing != null) return existing;
    final id = await deviceIdentity.getDeviceId();
    _deviceId = id;
    return id;
  }

  /// Loads and re-validates the stored license, creating a fresh trial when
  /// none exists or the stored key does not belong to this device.
  Future<void> load() async {
    emit(const PlansLoading());
    try {
      final deviceId = await resolveDeviceId();
      final stored = await repository.getLicense();
      if (stored == null) {
        await _startTrial(deviceId);
        return;
      }

      final check = LicenseKeyService.validate(
        stored.key,
        deviceId: deviceId,
      );
      switch (check.reason) {
        case LicenseCheckReason.valid:
          final validated = check.license!;
          _apply(
            LicenseEntity(
              key: validated.key,
              tier: validated.tier,
              activatedAt: stored.activatedAt,
              expiresAt: validated.expiresAt,
              customerName: stored.customerName,
              isTrial: validated.isTrial,
            ),
          );
          _emitLoaded();
        case LicenseCheckReason.expired:
          // Keep the expired record so the UI can prompt for renewal and the
          // user does not get a fresh trial every time the key expires.
          _apply(stored);
          _emitLoaded();
        case LicenseCheckReason.invalidSignature:
        case LicenseCheckReason.wrongDevice:
        case LicenseCheckReason.malformed:
          await _startTrial(deviceId);
      }
    } catch (e) {
      emit(PlansError('تعذر تحميل بيانات الترخيص: $e'));
    }
  }

  Future<void> refresh() => load();

  /// Validates [rawKey] against this device and persists it.
  /// Returns `null` on success or a user-facing error message on failure.
  Future<String?> activate(String rawKey) async {
    try {
      final deviceId = await resolveDeviceId();
      final check = LicenseKeyService.validate(rawKey, deviceId: deviceId);
      if (!check.isValid) {
        return check.error ?? 'مفتاح التفعيل غير صالح';
      }
      final license = check.license!;
      await repository.saveLicense(license);
      _apply(license);
      _emitLoaded();
      return null;
    } catch (e) {
      return 'تعذر حفظ الترخيص: $e';
    }
  }

  /// Debug/testing helper: forgets the current license and starts a new
  /// device-bound trial period on next [load].
  Future<void> resetActivation() async {
    try {
      await repository.clearLicense();
      await load();
    } catch (e) {
      emit(PlansError('تعذر إلغاء التفعيل: $e'));
    }
  }

  Future<void> _startTrial(String deviceId) async {
    final trial = LicenseKeyService.trialLicense(deviceId: deviceId);
    await repository.saveLicense(trial);
    _apply(trial);
    _emitLoaded();
  }

  void _apply(LicenseEntity license) {
    _license = license;
    _expired = license.isExpired;
    _plan = PlansCatalog.effectivePlanFor(
      license.tier,
      expired: _expired,
    );
    PlanCache.update(plan: _plan, license: license, expired: _expired);
  }

  void _emitLoaded() {
    emit(
      PlansLoaded(
        plan: _plan,
        license: _license,
        expired: _expired,
        trial: isTrial,
        daysRemaining: isTrial ? _license?.daysRemaining : null,
        deviceId: _deviceId,
      ),
    );
  }

  /// The plan the user would reach by activating [tier], used by the UI to
  /// decide between "ترقية" and "تغيير الخطة".
  bool isUpgradeTo(PlanTier tier) => tier.rank > _plan.tier.rank;
}
