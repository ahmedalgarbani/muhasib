/// Subscription tiers supported by the offline licensing system.
///
/// [code] is the single character embedded inside a license key, so never
/// change an existing code or previously issued keys become invalid.
enum PlanTier {
  free(code: 'F', nameAr: 'المجانية', rank: 0),
  basic(code: 'B', nameAr: 'الأساسية', rank: 1),
  pro(code: 'P', nameAr: 'الاحترافية', rank: 2),
  enterprise(code: 'E', nameAr: 'الأعمال', rank: 3),
  trial(code: 'T', nameAr: 'التجريبية', rank: 2);

  const PlanTier({
    required this.code,
    required this.nameAr,
    required this.rank,
  });

  final String code;
  final String nameAr;
  final int rank;

  static PlanTier? fromCode(String code) {
    for (final tier in PlanTier.values) {
      if (tier.code == code.toUpperCase()) return tier;
    }
    return null;
  }
}
