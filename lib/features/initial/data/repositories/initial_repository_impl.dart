import 'package:muhasib/features/initial/data/datasources/initial_local_datasource.dart';
import 'package:muhasib/features/initial/domain/entities/initial_setup_status.dart';
import 'package:muhasib/features/initial/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/initial/domain/repositories/initial_repository.dart';
import '../templates/opening_balance_accounting_template.dart';
import 'package:muhasib/core/services/database_service.dart';

class InitialRepositoryImpl implements InitialRepository {
  final InitialLocalDataSource localDataSource;
  final DatabaseService databaseService;
  late final OpeningBalanceAccountingTemplate _accountingTemplate;

  InitialRepositoryImpl({
    required this.localDataSource,
    required this.databaseService,
  }) {
    _accountingTemplate = OpeningBalanceAccountingTemplate(databaseService);
  }

  @override
  Future<InitialSetupStatus> getStatus() async {
    final isComplete = await localDataSource.isInitialSetupComplete();
    return InitialSetupStatus(isComplete: isComplete);
  }

  @override
  Future<void> completeInitialSetup() async {
    await localDataSource.setInitialSetupComplete();
  }

  @override
  Future<void> saveOpeningBalances(List<OpeningBalanceEntity> balances) async {
    if (balances.isEmpty) return;
    
    await _accountingTemplate.createOpeningBalanceEntries(
      openingBalances: balances,
      date: balances.first.date,
      statement: 'الأرصدة الافتتاحية للنظام',
    );
  }

  @override
  Future<List<OpeningBalanceEntity>> getOpeningBalances() async {
    final db = await databaseService.database;
    final result = await db.rawQuery('''
      SELECT 
        oel.id,
        oel.account_id,
        a.name as account_name,
        a.code as account_code,
        CASE WHEN oel.type = 1 THEN oel.amount ELSE 0 END as debit_amount,
        CASE WHEN oel.type = 2 THEN oel.amount ELSE 0 END as credit_amount,
        a.balance,
        oel.currency_code,
        oel.exchange_rate,
        oel.statement,
        oe.date
      FROM opening_entry_lines oel
      JOIN opening_entries oe ON oel.opening_entry_id = oe.id
      JOIN accounts a ON oel.account_id = a.id
      ORDER BY a.code
    ''');

    return result.map((row) => OpeningBalanceEntity(
      id: row['id'] as int?,
      accountId: row['account_id'] as int,
      accountName: row['account_name'] as String,
      accountCode: row['account_code'] as String,
      debitAmount: (row['debit_amount'] as num).toDouble(),
      creditAmount: (row['credit_amount'] as num).toDouble(),
      balance: (row['balance'] as num).toDouble(),
      currencyCode: row['currency_code'] as String?,
      exchangeRate: row['exchange_rate'] as double?,
      statement: row['statement'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch((row['date'] as int) * 1000),
    )).toList();
  }

  @override
  Future<bool> hasOpeningBalances() async {
    final db = await databaseService.database;
    final result = await db.query('opening_entries', limit: 1);
    return result.isNotEmpty;
  }

  @override
  Future<Map<String, dynamic>> getOpeningBalanceStatus() async {
    return await _accountingTemplate.getOpeningBalanceStatus();
  }

  @override
  Future<void> deleteOpeningBalances() async {
    final db = await databaseService.database;
    await db.transaction((txn) async {
      // Delete opening entries (will cascade delete lines)
      await txn.delete('opening_entries');
      
      // Delete related journal entries
      await txn.delete(
        'journal_entries',
        where: 'reference_type = ?',
        whereArgs: ['opening_balance'],
      );
      
      // Reset account balances to zero
      await txn.update(
        'accounts',
        {'balance': 0.0, 'local_balance': 0.0},
      );
    });
  }
}

