import 'package:muhasib/features/plans/data/datasources/plan_local_datasource.dart';
import 'package:muhasib/features/plans/domain/entities/license_entity.dart';
import 'package:muhasib/features/plans/domain/repositories/plan_repository.dart';

class PlanRepositoryImpl implements IPlanRepository {
  final PlanLocalDataSource localDataSource;

  PlanRepositoryImpl({required this.localDataSource});

  @override
  Future<LicenseEntity?> getLicense() => localDataSource.getLicense();

  @override
  Future<void> saveLicense(LicenseEntity license) =>
      localDataSource.saveLicense(license);

  @override
  Future<void> clearLicense() => localDataSource.clearLicense();
}
