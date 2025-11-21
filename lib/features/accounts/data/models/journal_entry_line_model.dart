import '../../domain/entities/journal_entry_entity.dart';

class JournalEntryLineModel extends JournalEntryLineEntity {
  const JournalEntryLineModel({
    int? id,
    int? journalEntryId,
    required int lineNumber,
    int? accountId,
    String? accountCode,
    required String accountName,
    int? currencyId,
    required String currencyCode,
    required double debit,
    required double credit,
    String? notes,
  }) : super(
          id: id,
          journalEntryId: journalEntryId,
          lineNumber: lineNumber,
          accountId: accountId,
          accountCode: accountCode,
          accountName: accountName,
          currencyId: currencyId,
          currencyCode: currencyCode,
          debit: debit,
          credit: credit,
          notes: notes,
        );

  factory JournalEntryLineModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryLineModel(
      id: json['id'] as int?,
      journalEntryId: json['journal_entry_id'] as int?,
      lineNumber: json['line_number'] as int,
      accountId: json['account_id'] as int?,
      accountCode: json['account_code'] as String?,
      accountName: json['account_name'] as String,
      currencyId: json['currency_id'] as int?,
      currencyCode: json['currency_code'] as String,
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  factory JournalEntryLineModel.fromEntity(JournalEntryLineEntity entity) {
    return JournalEntryLineModel(
      id: entity.id,
      journalEntryId: entity.journalEntryId,
      lineNumber: entity.lineNumber,
      accountId: entity.accountId,
      accountCode: entity.accountCode,
      accountName: entity.accountName,
      currencyId: entity.currencyId,
      currencyCode: entity.currencyCode,
      debit: entity.debit,
      credit: entity.credit,
      notes: entity.notes,
    );
  }

  Map<String, dynamic> toJson({required int journalEntryId}) {
    return {
      'journal_entry_id': journalEntryId,
      'line_number': lineNumber,
      'account_id': accountId,
      'account_code': accountCode,
      'account_name': accountName,
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'debit': debit,
      'credit': credit,
      'notes': notes,
    };
  }
}
