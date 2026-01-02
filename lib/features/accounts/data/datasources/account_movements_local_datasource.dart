import 'package:muhasib/features/accounts/data/models/account_movement_model.dart';
import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';
import 'package:sqflite/sqflite.dart';

abstract class AccountMovementsLocalDataSource {
  Future<List<AccountMovementModel>> getAccountMovements({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  });

  Future<AccountMovementsSummary> getAccountMovementsSummary({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class AccountMovementsLocalDataSourceImpl implements AccountMovementsLocalDataSource {
  final Database database;

  AccountMovementsLocalDataSourceImpl({required this.database});

  @override
  Future<List<AccountMovementModel>> getAccountMovements({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;
    
    final limitClause = limit != null ? 'LIMIT $limit' : '';

    final result = await database.rawQuery('''
      SELECT 
        jel.id,
        jel.journal_entry_id,
        je.entry_date,
        COALESCE(je.description, '') as description,
        COALESCE(je.reference_number, je.number, '') as reference,
        COALESCE(jel.debit_amount, 0) as debit_amount,
        COALESCE(jel.credit_amount, 0) as credit_amount
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = ?
      AND je.entry_date >= ? AND je.entry_date <= ?
      ORDER BY je.entry_date ASC, jel.id ASC
      $limitClause
    ''', [accountId, startTimestamp, endTimestamp]);

    // Calculate running balance
    double runningBalance = 0.0;
    final movementsWithBalance = <AccountMovementModel>[];
    
    for (final row in result) {
      final debit = (row['debit_amount'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['credit_amount'] as num?)?.toDouble() ?? 0.0;
      runningBalance += (debit - credit);
      
      movementsWithBalance.add(AccountMovementModel.fromMap({
        ...row,
        'balance': runningBalance,
      }));
    }

    return movementsWithBalance;
  }

  @override
  Future<AccountMovementsSummary> getAccountMovementsSummary({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final result = await database.rawQuery('''
      SELECT 
        COUNT(jel.id) as transaction_count,
        COALESCE(SUM(jel.debit_amount), 0) as total_debit,
        COALESCE(SUM(jel.credit_amount), 0) as total_credit
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = ?
      AND je.entry_date >= ? AND je.entry_date <= ?
    ''', [accountId, startTimestamp, endTimestamp]);

    if (result.isEmpty) {
      return const AccountMovementsSummary(
        totalDebit: 0,
        totalCredit: 0,
        netBalance: 0,
        transactionCount: 0,
      );
    }

    final row = result.first;
    final totalDebit = (row['total_debit'] as num?)?.toDouble() ?? 0.0;
    final totalCredit = (row['total_credit'] as num?)?.toDouble() ?? 0.0;

    return AccountMovementsSummary(
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      netBalance: totalDebit - totalCredit,
      transactionCount: (row['transaction_count'] as int?) ?? 0,
    );
  }
}
