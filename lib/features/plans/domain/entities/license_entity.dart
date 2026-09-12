import 'package:equatable/equatable.dart';
import 'plan_tier.dart';

/// A locally stored activation record. The tier and expiry are always
/// re-derived from [key] by the validation service, so a tampered database
/// row cannot unlock a higher plan.
class LicenseEntity extends Equatable {
  final String key;
  final PlanTier tier;
  final DateTime activatedAt;
  final DateTime? expiresAt;
  final String? customerName;
  final bool isTrial;

  const LicenseEntity({
    required this.key,
    required this.tier,
    required this.activatedAt,
    this.expiresAt,
    this.customerName,
    this.isTrial = false,
  });

  bool get isPerpetual => expiresAt == null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  int? get daysRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Masked form safe to display on screen, e.g. `MHSB-P-••••-••••-7F3A`.
  String get maskedKey {
    if (key.length <= 9) return key;
    return '${key.substring(0, 6)}-••••-••••-${key.substring(key.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'tier': tier.name,
      'activated_at': activatedAt.millisecondsSinceEpoch,
      'expires_at': expiresAt?.millisecondsSinceEpoch,
      'customer_name': customerName,
      'is_trial': isTrial,
    };
  }

  factory LicenseEntity.fromMap(Map<String, dynamic> map) {
    final tierName = map['tier']?.toString();
    final tier = PlanTier.values.firstWhere(
      (t) => t.name == tierName,
      orElse: () => PlanTier.free,
    );
    return LicenseEntity(
      key: map['key']?.toString() ?? '',
      tier: tier,
      activatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['activated_at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['expires_at'] as num).toInt(),
            ),
      customerName: map['customer_name']?.toString(),
      isTrial: map['is_trial'] == true,
    );
  }

  @override
  List<Object?> get props =>
      [key, tier, activatedAt, expiresAt, customerName, isTrial];
}
