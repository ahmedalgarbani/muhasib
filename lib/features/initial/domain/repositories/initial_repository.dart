import '../entities/initial_setup_status.dart';
import '../entities/opening_balance_entity.dart';

abstract class InitialRepository {
  Future<InitialSetupStatus> getStatus();
  Future<void> completeInitialSetup();
  Future<void> saveOpeningBalances(List<OpeningBalanceEntity> balances);
  Future<List<OpeningBalanceEntity>> getOpeningBalances();
  Future<bool> hasOpeningBalances();
  Future<Map<String, dynamic>> getOpeningBalanceStatus();
  Future<void> deleteOpeningBalances();
}

