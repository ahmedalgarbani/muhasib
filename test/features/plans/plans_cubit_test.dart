import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/plans/domain/entities/license_entity.dart';
import 'package:muhasib/features/plans/domain/entities/plan_tier.dart';
import 'package:muhasib/features/plans/domain/repositories/plan_repository.dart';
import 'package:muhasib/features/plans/domain/services/device_identity_service.dart';
import 'package:muhasib/features/plans/domain/services/license_key_service.dart';
import 'package:muhasib/features/plans/domain/services/plan_cache.dart';
import 'package:muhasib/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:muhasib/features/plans/presentation/cubit/plans_state.dart';

class _FakePlanRepository implements IPlanRepository {
  LicenseEntity? stored;

  @override
  Future<LicenseEntity?> getLicense() async => stored;

  @override
  Future<void> saveLicense(LicenseEntity license) async => stored = license;

  @override
  Future<void> clearLicense() async => stored = null;
}

class _FakeDeviceIdentity implements DeviceIdentityService {
  _FakeDeviceIdentity(this.id);

  final String id;

  @override
  Future<String> getDeviceId() async => id;
}

LicenseEntity _paidLicense({
  required String deviceId,
  DateTime? expiresAt,
  PlanTier tier = PlanTier.pro,
}) {
  final expiry = expiresAt ?? DateTime.now().add(const Duration(days: 365));
  return LicenseEntity(
    key: LicenseKeyService.generate(
      tier: tier,
      deviceId: deviceId,
      expiresAt: expiry,
    ),
    tier: tier,
    activatedAt: DateTime.now(),
    expiresAt: expiry,
  );
}

void main() {
  setUp(PlanCache.reset);
  tearDown(PlanCache.reset);

  test('load starts a device-bound trial when nothing is stored', () async {
    final repository = _FakePlanRepository();
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );

    await cubit.load();

    final state = cubit.state as PlansLoaded;
    expect(state.trial, isTrue);
    expect(state.deviceId, 'DEV-A');
    expect(repository.stored, isNotNull);
    expect(
      LicenseKeyService.validate(
        repository.stored!.key,
        deviceId: 'DEV-A',
      ).isValid,
      isTrue,
    );
    expect(
      LicenseKeyService.validate(
        repository.stored!.key,
        deviceId: 'DEV-B',
      ).reason,
      LicenseCheckReason.wrongDevice,
    );
  });

  test('activate binds a paid plan to this device', () async {
    final repository = _FakePlanRepository();
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );
    await cubit.load();

    final key = LicenseKeyService.generate(
      tier: PlanTier.pro,
      deviceId: 'DEV-A',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
    final error = await cubit.activate(key);

    expect(error, isNull);
    expect((cubit.state as PlansLoaded).plan.tier, PlanTier.pro);
    expect(PlanCache.plan.tier, PlanTier.pro);
    expect(repository.stored!.tier, PlanTier.pro);
  });

  test('activate rejects a key issued for another device', () async {
    final repository = _FakePlanRepository();
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );
    await cubit.load();

    final key = LicenseKeyService.generate(
      tier: PlanTier.pro,
      deviceId: 'DEV-B',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
    final error = await cubit.activate(key);

    expect(error, isNotNull);
    expect((cubit.state as PlansLoaded).plan.tier, PlanTier.trial);
    expect(repository.stored!.tier, PlanTier.trial);
  });

  test('a stored key for another device falls back to a new trial', () async {
    final repository = _FakePlanRepository();
    repository.stored = _paidLicense(deviceId: 'DEV-B');
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );

    await cubit.load();

    expect(cubit.isTrial, isTrue);
    expect(repository.stored!.isTrial, isTrue);
    expect(
      LicenseKeyService.validate(
        repository.stored!.key,
        deviceId: 'DEV-A',
      ).isValid,
      isTrue,
    );
  });

  test('an expired stored license stays expired without a new trial',
      () async {
    final repository = _FakePlanRepository();
    final past = DateTime.now().subtract(const Duration(days: 1));
    final stored = _paidLicense(deviceId: 'DEV-A', expiresAt: past);
    repository.stored = stored;
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );

    await cubit.load();

    final state = cubit.state as PlansLoaded;
    expect(state.expired, isTrue);
    expect(state.plan.tier, PlanTier.free);
    expect(cubit.isTrial, isFalse);
    expect(repository.stored!.key, stored.key);
  });

  test('resetActivation clears the license and starts a new trial', () async {
    final repository = _FakePlanRepository();
    repository.stored = _paidLicense(deviceId: 'DEV-A');
    final cubit = PlansCubit(
      repository: repository,
      deviceIdentity: _FakeDeviceIdentity('DEV-A'),
    );
    await cubit.load();
    expect(cubit.plan.tier, PlanTier.pro);

    await cubit.resetActivation();

    expect(cubit.isTrial, isTrue);
    expect(repository.stored!.isTrial, isTrue);
  });
}
