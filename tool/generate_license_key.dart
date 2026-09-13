import 'dart:io';

import 'package:muhasib/features/plans/domain/entities/plan_tier.dart';
import 'package:muhasib/features/plans/domain/services/license_key_service.dart';

const _usage = '''
Usage: dart run tool/generate_license_key.dart --device <deviceId> [options]

Required:
  --device <id>   Device ID shown on the app's activation screen, e.g.
                  2F8A-91BC-77DE-4410. Keys only work on this device.

Options:
  --tier <free|basic|pro|enterprise|trial>   Plan tier (default: pro)
  --years <n>     Validity in years from today (default: 1)
  --days <n>      Validity in days from today (overrides --years)
  --date <yyyy-mm-dd>  Fixed expiry date (overrides --years/--days)
  --perpetual     Generates a license that never expires
  --count <n>     How many keys to generate (default: 1)
  --examples      Prints one ready-to-copy key for every plan/status

Copy one of these for any status:

  # Basic plan, perpetual license
  dart run tool/generate_license_key.dart --device <id> --tier basic --perpetual

  # Pro plan, valid for one year
  dart run tool/generate_license_key.dart --device <id> --tier pro --years 1

  # Pro plan, valid for one month
  dart run tool/generate_license_key.dart --device <id> --tier pro --days 30

  # Enterprise plan, perpetual
  dart run tool/generate_license_key.dart --device <id> --tier enterprise --perpetual

  # Trial plan, 14 days
  dart run tool/generate_license_key.dart --device <id> --tier trial --days 14

  # Expired key (for UI testing only)
  dart run tool/generate_license_key.dart --device <id> --tier pro --date 2020-01-01

  # Every status above in one copy-ready list
  dart run tool/generate_license_key.dart --device <id> --examples
''';

void main(List<String> args) {
  final deviceArg = _option(args, '--device');
  if (deviceArg == null || deviceArg.trim().isEmpty) {
    stderr.writeln('Missing required --device argument.');
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  if (args.contains('--examples')) {
    _printExamples(deviceArg);
    return;
  }

  final tierArg = _option(args, '--tier') ?? 'pro';
  PlanTier? tier;
  for (final candidate in PlanTier.values) {
    if (candidate.name == tierArg) {
      tier = candidate;
      break;
    }
  }
  if (tier == null) {
    stderr.writeln('Unknown tier "$tierArg".');
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final perpetual = args.contains('--perpetual');
  final dateArg = _option(args, '--date');
  final days = int.tryParse(_option(args, '--days') ?? '');
  final years = int.tryParse(_option(args, '--years') ?? '') ?? 1;
  final count = int.tryParse(_option(args, '--count') ?? '') ?? 1;
  if (count < 1) {
    stderr.writeln('--count must be >= 1');
    exitCode = 64;
    return;
  }

  DateTime? expiresAt;
  if (!perpetual) {
    if (dateArg != null) {
      expiresAt = DateTime.tryParse(dateArg);
      if (expiresAt == null) {
        stderr.writeln('Invalid --date "$dateArg", expected yyyy-mm-dd.');
        exitCode = 64;
        return;
      }
      expiresAt = _endOfDay(expiresAt);
    } else if (days != null && days > 0) {
      expiresAt = DateTime.now().add(Duration(days: days));
    } else {
      final now = DateTime.now();
      expiresAt = _endOfDay(
        DateTime(now.year + years, now.month, now.day),
      );
    }
  }

  stdout.writeln('Tier       : ${tier.nameAr} (${tier.name})');
  stdout.writeln('Device ID  : $deviceArg');
  stdout.writeln(
    'Fingerprint: ${LicenseKeyService.deviceFingerprint(deviceArg)}',
  );
  stdout.writeln(
    'Expires    : ${expiresAt == null ? 'PERPETUAL' : expiresAt.toIso8601String()}',
  );
  stdout.writeln('Keys       :');

  for (var i = 0; i < count; i++) {
    final key = LicenseKeyService.generate(
      tier: tier,
      deviceId: deviceArg,
      expiresAt: expiresAt,
    );
    final check = LicenseKeyService.validate(key, deviceId: deviceArg);
    stdout.writeln('  ${check.isValid ? 'OK ' : 'BAD'}  $key');
  }
}

/// Prints one generated key for every plan/status so a key can be copied
/// directly into the app's activation screen (device binding still applies).
void _printExamples(String deviceId) {
  final now = DateTime.now();

  final examples = <List<String>>[
    [
      'المجانية - ترخيص دائم',
      LicenseKeyService.generate(tier: PlanTier.free, deviceId: deviceId),
    ],
    [
      'الأساسية - ترخيص دائم',
      LicenseKeyService.generate(tier: PlanTier.basic, deviceId: deviceId),
    ],
    [
      'الأساسية - سنة واحدة',
      LicenseKeyService.generate(
        tier: PlanTier.basic,
        deviceId: deviceId,
        expiresAt: _endOfDay(DateTime(now.year + 1, now.month, now.day)),
      ),
    ],
    [
      'الاحترافية - ترخيص دائم',
      LicenseKeyService.generate(tier: PlanTier.pro, deviceId: deviceId),
    ],
    [
      'الاحترافية - سنة واحدة',
      LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: deviceId,
        expiresAt: _endOfDay(DateTime(now.year + 1, now.month, now.day)),
      ),
    ],
    [
      'الاحترافية - شهر',
      LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: deviceId,
        expiresAt: now.add(const Duration(days: 30)),
      ),
    ],
    [
      'الأعمال - ترخيص دائم',
      LicenseKeyService.generate(tier: PlanTier.enterprise, deviceId: deviceId),
    ],
    [
      'الأعمال - سنة واحدة',
      LicenseKeyService.generate(
        tier: PlanTier.enterprise,
        deviceId: deviceId,
        expiresAt: _endOfDay(DateTime(now.year + 1, now.month, now.day)),
      ),
    ],
    [
      'التجريبية - 14 يوم',
      LicenseKeyService.generate(
        tier: PlanTier.trial,
        deviceId: deviceId,
        expiresAt: now.add(const Duration(days: 14)),
      ),
    ],
    [
      'منتهية - للاختبار فقط (سيتم رفضها)',
      LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: deviceId,
        expiresAt: _endOfDay(DateTime(2020, 1, 1)),
      ),
    ],
    [
      'جهاز آخر - للاختبار فقط (سيتم رفضها هنا)',
      LicenseKeyService.generate(
        tier: PlanTier.pro,
        deviceId: 'SAMPLE-OTHER-DEVICE-0000',
      ),
    ],
  ];

  stdout.writeln('Examples for device : $deviceId');
  stdout.writeln(
    'Fingerprint         : ${LicenseKeyService.deviceFingerprint(deviceId)}',
  );
  stdout.writeln('Copy only the key line below the status you need:');
  stdout.writeln('');

  for (var i = 0; i < examples.length; i++) {
    stdout.writeln('[${i + 1}] ${examples[i][0]}');
    stdout.writeln('    ${examples[i][1]}');
    stdout.writeln('');
  }

  stdout.writeln(
    'Note: the last two keys are intentionally rejected (expired / other device).',
  );
}

DateTime _endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59);

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
