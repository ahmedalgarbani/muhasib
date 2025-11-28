import '../repositories/initial_repository.dart';

class MarkInitialSetupComplete {
  final InitialRepository repository;

  MarkInitialSetupComplete(this.repository);

  Future<void> call() async {
    return await repository.completeInitialSetup();
  }
}

