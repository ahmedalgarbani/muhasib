import '../entities/opening_balance_entity.dart';
import '../repositories/initial_repository.dart';

class SaveOpeningBalances {
  final InitialRepository repository;

  SaveOpeningBalances(this.repository);

  Future<void> call(List<OpeningBalanceEntity> balances) async {
    return await repository.saveOpeningBalances(balances);
  }
}
