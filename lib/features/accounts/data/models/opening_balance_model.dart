import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';

class OpeningBalanceModel extends OpeningBalanceEntity {
  const OpeningBalanceModel({
    super.id,
    required super.number,
    required super.entryDate,
    super.description,
    super.notes,
    required super.currencyId,
    required super.currencyCode,
    super.status,
    super.isPosted,
    required super.totalDebit,
    required super.totalCredit,
    required super.lines,
    super.creatorId,
    super.creationTime,
    super.lastModificationTime,
  });

  factory OpeningBalanceModel.fromMap(Map<String, dynamic> map, List<OpeningBalanceLineModel> lines) {
    return OpeningBalanceModel(
      id: map['id'] as int?,
      number: map['number'] as String,
      entryDate: DateTime.fromMillisecondsSinceEpoch((map['entry_date'] as int) * 1000),
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      currencyId: map['currency_id'] ?? 1,
      currencyCode: map['currency_code'] ?? 'SAR',
      status: map['status'] as int? ?? 0,
      isPosted: (map['is_posted'] as int? ?? 0) == 1,
      totalDebit: map['total_debit'] as double? ?? 0.0,
      totalCredit: map['total_credit'] as double? ?? 0.0,
      lines: lines,
      creatorId: map['creator_id'] as int?,
      creationTime: map['creation_time'] as int?,
      lastModificationTime: map['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'entry_date': entryDate.millisecondsSinceEpoch ~/ 1000,
      'description': description ?? 'رصيد افتتاحي',
      'notes': notes,
      'status': status,
      'is_posted': isPosted ? 1 : 0,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': difference,
      'creator_id': creatorId ?? 1,
      'creation_time': creationTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  factory OpeningBalanceModel.fromEntity(OpeningBalanceEntity entity) {
    return OpeningBalanceModel(
      id: entity.id,
      number: entity.number,
      entryDate: entity.entryDate,
      description: entity.description,
      notes: entity.notes,
      currencyId: entity.currencyId,
      currencyCode: entity.currencyCode,
      status: entity.status,
      isPosted: entity.isPosted,
      totalDebit: entity.totalDebit,
      totalCredit: entity.totalCredit,
      lines: entity.lines.map((line) => OpeningBalanceLineModel.fromEntity(line)).toList(),
      creatorId: entity.creatorId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  OpeningBalanceEntity toEntity() {
    return OpeningBalanceEntity(
      id: id,
      number: number,
      entryDate: entryDate,
      description: description,
      notes: notes,
      currencyId: currencyId,
      currencyCode: currencyCode,
      status: status,
      isPosted: isPosted,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      lines: lines,
      creatorId: creatorId,
      creationTime: creationTime,
      lastModificationTime: lastModificationTime,
    );
  }
}

class OpeningBalanceLineModel extends OpeningBalanceLineEntity {
  const OpeningBalanceLineModel({
    super.id,
    required super.lineNumber,
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    required super.currencyId,
    required super.currencyCode,
    required super.debit,
    required super.credit,
    super.notes,
  });

  factory OpeningBalanceLineModel.fromMap(Map<String, dynamic> map) {
    return OpeningBalanceLineModel(
      id: map['id'] as int?,
      lineNumber: map['line_number'] as int,
      accountId: map['account_id'] as int,
      accountCode: map['account_code'] as String,
      accountName: map['account_name'] as String,
      currencyId: map['currency_id'] as int? ?? 1,
      currencyCode: map['currency_code'] as String? ?? 'SAR',
      debit: map['debit'] as double? ?? 0.0,
      credit: map['credit'] as double? ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap(int journalEntryId) {
    return {
      'id': id,
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

  factory OpeningBalanceLineModel.fromEntity(OpeningBalanceLineEntity entity) {
    return OpeningBalanceLineModel(
      id: entity.id,
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

  OpeningBalanceLineEntity toEntity() {
    return OpeningBalanceLineEntity(
      id: id,
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
  }
}
