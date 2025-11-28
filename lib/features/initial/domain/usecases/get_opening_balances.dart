import '../entities/opening_balance_entity.dart';
import '../repositories/initial_repository.dart';

class GetOpeningBalances {
  final InitialRepository repository;

  GetOpeningBalances(this.repository);

  Future<List<OpeningBalanceEntity>> call() async {
    return await repository.getOpeningBalances();
  }
}
