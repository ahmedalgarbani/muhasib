import '../entities/initial_setup_status.dart';
import '../repositories/initial_repository.dart';

class CheckInitialSetupStatus {
  final InitialRepository repository;

  CheckInitialSetupStatus(this.repository);

  Future<InitialSetupStatus> call() async {
    return await repository.getStatus();
  }
}

