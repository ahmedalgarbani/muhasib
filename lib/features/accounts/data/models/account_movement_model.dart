import 'package:muhasib/features/accounts/domain/entities/account_movement_entity.dart';

class AccountMovementModel extends AccountMovementEntity {
  const AccountMovementModel({
    required super.id,
    required super.journalEntryId,
    required super.entryDate,
    required super.description,
    required super.reference,
    required super.debitAmount,
    required super.creditAmount,
    required super.balance,
  });

  factory AccountMovementModel.fromMap(Map<String, dynamic> map) {
    // Handle entry_date as unix timestamp (seconds)
    final entryDateRaw = map['entry_date'];
    DateTime entryDate;
    if (entryDateRaw is int) {
      entryDate = DateTime.fromMillisecondsSinceEpoch(entryDateRaw * 1000);
    } else if (entryDateRaw is String) {
      entryDate = DateTime.tryParse(entryDateRaw) ?? DateTime.now();
    } else {
      entryDate = DateTime.now();
    }

    return AccountMovementModel(
      id: map['id'] as int? ?? 0,
      journalEntryId: map['journal_entry_id'] as int? ?? 0,
      entryDate: entryDate,
      description: map['description'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      debitAmount: (map['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['credit_amount'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'entry_date': entryDate.millisecondsSinceEpoch ~/ 1000,
      'description': description,
      'reference': reference,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'balance': balance,
    };
  }
}
