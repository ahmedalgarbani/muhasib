import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/plans/domain/entities/plan_tier.dart';
import 'package:muhasib/features/plans/domain/services/license_key_service.dart';

const _deviceA = 'DEVICE-AAAA-1111';
const _deviceB = 'DEVICE-BBBB-2222';

void main() {
  group('LicenseKeyService.generate', () {
    test('produces a deterministic, device-bound key', () {
      final date = DateTime(2026, 12, 31);
      final first = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
        expiresAt: date,
      );
      final second = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
        expiresAt: date,
      );
      expect(first, second);
      expect(first, startsWith('MHSB-P-20261231-'));
      expect(first.split('-').length, 8);
    });

    test('produces different keys per device', () {
      final keyA = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
      );
      final keyB = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceB,
      );
      expect(keyA, isNot(keyB));
    });

    test('generates perpetual keys', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.enterprise,
        deviceId: _deviceA,
      );
      expect(key, startsWith('MHSB-E-PERP-'));
    });
  });

  group('LicenseKeyService.validate', () {
    test('accepts a valid key on the matching device', () {
      final expiresAt = DateTime.now().add(const Duration(days: 365));
      final key = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
        expiresAt: expiresAt,
      );

      final result = LicenseKeyService.validate(key, deviceId: _deviceA);

      expect(result.isValid, isTrue);
      expect(result.license!.tier, PlanTier.pro);
      expect(result.license!.isTrial, isFalse);
      expect(result.license!.expiresAt!.year, expiresAt.year);
    });

    test('rejects a key issued for another device', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
      );

      final result = LicenseKeyService.validate(key, deviceId: _deviceB);

      expect(result.isValid, isFalse);
      expect(result.reason, LicenseCheckReason.wrongDevice);
    });

    test('accepts perpetual keys without expiry', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.basic,
        deviceId: _deviceA,
      );

      final result = LicenseKeyService.validate(key, deviceId: _deviceA);

      expect(result.isValid, isTrue);
      expect(result.license!.isPerpetual, isTrue);
      expect(result.license!.tier, PlanTier.basic);
    });

    test('rejects tampered signatures', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
      );
      final lastChar = key.endsWith('A') ? 'B' : 'A';
      final tampered = key.substring(0, key.length - 1) + lastChar;

      final result = LicenseKeyService.validate(tampered, deviceId: _deviceA);

      expect(result.isValid, isFalse);
      expect(result.reason, LicenseCheckReason.invalidSignature);
    });

    test('rejects a tampered device fingerprint', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
      );
      final parts = key.split('-');
      parts[3] = parts[3] == 'AAAAAA' ? 'BBBBBB' : 'AAAAAA';
      final tampered = parts.join('-');

      final result = LicenseKeyService.validate(tampered, deviceId: _deviceA);

      expect(result.isValid, isFalse);
    });

    test('rejects malformed keys', () {
      expect(
        LicenseKeyService.validate('', deviceId: _deviceA).isValid,
        isFalse,
      );
      expect(
        LicenseKeyService.validate(
          'MHSB-X-20261231-ABCDEF-AAAA',
          deviceId: _deviceA,
        ).isValid,
        isFalse,
      );
      expect(
        LicenseKeyService.validate(
          'MHSB-P-NOTADATE-ABCDEF-AAAA-BBBB-CCCC-DDDD',
          deviceId: _deviceA,
        ).isValid,
        isFalse,
      );
    });

    test('rejects expired keys', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.basic,
        deviceId: _deviceA,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final result = LicenseKeyService.validate(key, deviceId: _deviceA);

      expect(result.isValid, isFalse);
      expect(result.reason, LicenseCheckReason.expired);
      expect(result.error, contains('انتهت'));
    });

    test('is case-insensitive and ignores whitespace', () {
      final key = LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: _deviceA,
      );
      final messy = ' ${key.toLowerCase()} ';

      expect(
        LicenseKeyService.validate(messy, deviceId: _deviceA).isValid,
        isTrue,
      );
    });
  });

  group('deviceFingerprint', () {
    test('ignores case and separators', () {
      expect(
        LicenseKeyService.deviceFingerprint('dev-ice-1234'),
        LicenseKeyService.deviceFingerprint('DEVICE1234'),
      );
    });

    test('differs between devices', () {
      expect(
        LicenseKeyService.deviceFingerprint(_deviceA),
        isNot(LicenseKeyService.deviceFingerprint(_deviceB)),
      );
    });
  });

  group('trialLicense', () {
    test('creates a valid 30-day trial bound to the device', () {
      final trial = LicenseKeyService.trialLicense(deviceId: _deviceA);

      expect(trial.isTrial, isTrue);
      expect(trial.tier, PlanTier.trial);
      expect(trial.isExpired, isFalse);
      expect(trial.daysRemaining, inInclusiveRange(28, 30));
      expect(
        LicenseKeyService.validate(trial.key, deviceId: _deviceA).isValid,
        isTrue,
      );
      expect(
        LicenseKeyService.validate(trial.key, deviceId: _deviceB).reason,
        LicenseCheckReason.wrongDevice,
      );
    });
  });
}
