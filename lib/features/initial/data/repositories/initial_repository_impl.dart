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

    // Replace semantics: never create duplicate opening entries/journals.
    if (await hasOpeningBalances()) {
      await deleteOpeningBalances();
    }

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
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 1. Reverse each opening line's effect on account balances
      final lines = await txn.query(
        'opening_entry_lines',
        columns: ['account_id', 'amount', 'local_amount', 'type'],
      );
      for (final line in lines) {
        final accountId = line['account_id'] as int?;
        if (accountId == null) continue;
        final amount = (line['amount'] as num?)?.toDouble() ?? 0.0;
        final localAmount =
            (line['local_amount'] as num?)?.toDouble() ?? amount;
        final isDebit = (line['type'] as int?) == 1;
        final signed = isDebit ? -amount : amount;
        final signedLocal = isDebit ? -localAmount : localAmount;

        await txn.rawUpdate(
          'UPDATE accounts '
          'SET balance = balance + ?, local_balance = local_balance + ?, last_modification_time = ? '
          'WHERE id = ?',
          [signed, signedLocal, now, accountId],
        );
      }

      // 2. Remove generated opening journal entries, scoped to THIS feature's
      //    opening_entries. Customer/product opening-balance journals also use
      //    reference_type='opening_balance' and must not be touched.
      final openingRows = await txn.query('opening_entries', columns: ['id']);
      final openingIds = openingRows.map((r) => r['id'] as int).toList();
      if (openingIds.isNotEmpty) {
        final placeholders = List.filled(openingIds.length, '?').join(',');
        final journalRows = await txn.query(
          'journal_entries',
          columns: ['id'],
          where: 'reference_type = ? AND reference_id IN ($placeholders)',
          whereArgs: ['opening_balance', ...openingIds],
        );
        final journalIds = journalRows.map((r) => r['id'] as int).toList();
        if (journalIds.isNotEmpty) {
          final journalPlaceholders = List.filled(
            journalIds.length,
            '?',
          ).join(',');
          await txn.delete(
            'journal_entry_lines',
            where: 'journal_entry_id IN ($journalPlaceholders)',
            whereArgs: journalIds,
          );
          await txn.delete(
            'journal_entries',
            where: 'id IN ($journalPlaceholders)',
            whereArgs: journalIds,
          );
        }
      }

      // 3. Delete opening entry lines then opening entries (cascade-safe)
      await txn.delete('opening_entry_lines');
      await txn.delete('opening_entries');
    });
  }
}

