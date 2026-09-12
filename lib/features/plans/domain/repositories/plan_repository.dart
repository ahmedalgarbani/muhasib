import '../entities/license_entity.dart';

abstract class IPlanRepository {
  /// Returns the stored license or `null` when the app was never activated.
  Future<LicenseEntity?> getLicense();

  Future<void> saveLicense(LicenseEntity license);

  Future<void> clearLicense();
}
