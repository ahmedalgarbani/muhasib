import '../../domain/entities/journal_entry_entity.dart';

class JournalEntryLineModel extends JournalEntryLineEntity {
  const JournalEntryLineModel({
    super.id,
    super.journalEntryId,
    required super.lineNumber,
    super.accountId,
    super.accountCode,
    required super.accountName,
    super.currencyId,
    required super.currencyCode,
    required super.debit,
    required super.credit,
    super.notes,
  });

  factory JournalEntryLineModel.fromJson(Map<String, dynamic> json) {
    // journal_entry_lines schema uses debit_amount/credit_amount
    final rawDebit = json['debit_amount'] ?? json['debit'];
    final rawCredit = json['credit_amount'] ?? json['credit'];
    return JournalEntryLineModel(
      id: json['id'] as int?,
      journalEntryId: json['journal_entry_id'] as int?,
      lineNumber: (json['line_number'] as int?) ?? 0,
      accountId: json['account_id'] as int?,
      accountCode: json['account_code'] as String?,
      accountName: (json['account_name'] as String?) ?? '',
      currencyId: json['currency_id'] as int?,
      currencyCode: (json['currency_code'] as String?) ?? '',
      debit: (rawDebit as num?)?.toDouble() ?? 0.0,
      credit: (rawCredit as num?)?.toDouble() ?? 0.0,
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
      'debit_amount': debit,
      'credit_amount': credit,
      'notes': notes,
    };
  }
}
