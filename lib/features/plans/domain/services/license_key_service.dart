import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/license_entity.dart';
import '../entities/plan_tier.dart';

/// Why a license key was rejected.
enum LicenseCheckReason {
  valid,
  malformed,
  invalidSignature,
  wrongDevice,
  expired,
}

/// Result of validating a raw license key typed by the user.
class LicenseCheck {
  final LicenseEntity? license;
  final LicenseCheckReason reason;
  final String? error;

  const LicenseCheck.valid(LicenseEntity this.license)
      : reason = LicenseCheckReason.valid,
        error = null;

  const LicenseCheck.invalid(this.reason, String this.error) : license = null;

  bool get isValid => license != null;
}

/// Offline, device-bound license key generator/validator.
///
/// Key format (human typeable, no ambiguous characters):
///
///     MHSB-<TIER>-<YYYYMMDD|PERP>-<DEVFINGERPRINT(6)>-XXXX-XXXX-XXXX-XXXX
///
/// The 16-character signature is a truncated HMAC-SHA256 of the payload
/// `MHSB1|<TIER>|<EXPIRY>|<DEVFINGERPRINT>` using [_secret]. The 6-character
/// device fingerprint is derived from the customer's device ID, so a key
/// only validates on the device it was issued for.
class LicenseKeyService {
  LicenseKeyService._();

  /// Shared secret. The same value must be used by the key generator tool.
  static const String _secret =
      'muhasib-pos-2026|v1|7f4c9b2e1a8d6350f2b84c9e5d17a3';

  static const String _prefix = 'MHSB';
  static const String _payloadVersion = 'MHSB1';
  static const String _deviceSalt = 'MHSB-DEV|';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const String _perpetual = 'PERP';
  static const int _signatureLength = 16;
  static const int _fingerprintLength = 6;
  static const int trialDays = 14;

  static final RegExp _keyPattern = RegExp(
    r'^MHSB-([A-Z])-(\d{8}|PERP)-([A-Z2-9]{6})-([A-Z0-9]{4})-([A-Z0-9]{4})-([A-Z0-9]{4})-([A-Z0-9]{4})$',
  );

  /// Creates a trial license bound to [deviceId] with [days] validity and
  /// Professional-level entitlements. Used once per install.
  static LicenseEntity trialLicense({
    required String deviceId,
    int days = trialDays,
  }) {
    final now = DateTime.now();
    final expiry = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).add(Duration(days: days));
    final key = generate(
      tier: PlanTier.trial,
      expiresAt: expiry,
      deviceId: deviceId,
    );
    return LicenseEntity(
      key: key,
      tier: PlanTier.trial,
      activatedAt: now,
      expiresAt: expiry,
      isTrial: true,
    );
  }

  /// Generates a license key bound to [deviceId].
  ///
  /// Pass `expiresAt: null` for a perpetual license. Only use this from the
  /// sales tool — the app never needs to generate paid keys.
  static String generate({
    required PlanTier tier,
    required String deviceId,
    DateTime? expiresAt,
  }) {
    final expiryToken =
        expiresAt == null ? _perpetual : _formatDate(expiresAt);
    final fingerprint = deviceFingerprint(deviceId);
    final signature = _signature(_payload(tier, expiryToken, fingerprint));
    final groups = <String>[
      for (var i = 0; i < _signatureLength; i += 4)
        signature.substring(i, i + 4),
    ];
    return '$_prefix-${tier.code}-$expiryToken-$fingerprint-${groups.join('-')}';
  }

  /// Validates a key typed by the user and extracts the entitlement.
  ///
  /// [deviceId] must be the ID of the device performing the activation;
  /// keys issued for another device are rejected with
  /// [LicenseCheckReason.wrongDevice].
  static LicenseCheck validate(
    String raw, {
    required String deviceId,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final normalized = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final match = _keyPattern.firstMatch(normalized);
    if (match == null) {
      return const LicenseCheck.invalid(
        LicenseCheckReason.malformed,
        'صيغة مفتاح التفعيل غير صحيحة',
      );
    }

    final tier = PlanTier.fromCode(match.group(1)!);
    if (tier == null) {
      return const LicenseCheck.invalid(
        LicenseCheckReason.malformed,
        'إصدار الترخيص غير معروف',
      );
    }

    final expiryToken = match.group(2)!;
    final fingerprint = match.group(3)!;
    final signature = match.group(4)! +
        match.group(5)! +
        match.group(6)! +
        match.group(7)!;
    if (signature != _signature(_payload(tier, expiryToken, fingerprint))) {
      return const LicenseCheck.invalid(
        LicenseCheckReason.invalidSignature,
        'مفتاح التفعيل غير صالح',
      );
    }

    if (fingerprint != deviceFingerprint(deviceId)) {
      return const LicenseCheck.invalid(
        LicenseCheckReason.wrongDevice,
        'مفتاح التفعيل مخصص لجهاز آخر. تأكد من إرسال معرّف هذا الجهاز '
        'لفريق المبيعات عند الشراء.',
      );
    }

    DateTime? expiresAt;
    if (expiryToken != _perpetual) {
      expiresAt = _parseDate(expiryToken);
      if (expiresAt == null) {
        return const LicenseCheck.invalid(
          LicenseCheckReason.malformed,
          'تاريخ انتهاء الترخيص غير صحيح',
        );
      }
      if (expiresAt.isBefore(reference)) {
        return const LicenseCheck.invalid(
          LicenseCheckReason.expired,
          'انتهت صلاحية مفتاح التفعيل',
        );
      }
    }

    return LicenseCheck.valid(
      LicenseEntity(
        key: normalized,
        tier: tier,
        activatedAt: reference,
        expiresAt: expiresAt,
        isTrial: tier == PlanTier.trial,
      ),
    );
  }

  /// Short, non-reversible fingerprint of [deviceId] embedded in keys.
  static String deviceFingerprint(String deviceId) {
    final normalized = deviceId
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final digest = sha256.convert(utf8.encode('$_deviceSalt$normalized'));
    return _encodeBase32(digest.bytes).substring(0, _fingerprintLength);
  }

  static String _payload(
    PlanTier tier,
    String expiryToken,
    String fingerprint,
  ) =>
      '$_payloadVersion|${tier.code}|$expiryToken|$fingerprint';

  static String _signature(String payload) {
    final digest = Hmac(sha256, utf8.encode(_secret))
        .convert(utf8.encode(payload));
    return _encodeBase32(digest.bytes).substring(0, _signatureLength);
  }

  static String _encodeBase32(List<int> bytes) {
    final buffer = StringBuffer();
    var bits = 0;
    var value = 0;
    for (final byte in bytes) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        buffer.write(_alphabet[(value >> (bits - 5)) & 0x1F]);
        bits -= 5;
      }
    }
    if (bits > 0) {
      buffer.write(_alphabet[(value << (5 - bits)) & 0x1F]);
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String token) {
    if (token.length != 8) return null;
    final year = int.tryParse(token.substring(0, 4));
    final month = int.tryParse(token.substring(4, 6));
    final day = int.tryParse(token.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day, 23, 59, 59);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}
