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

  /// Creates model from opening_entries table row
  factory OpeningBalanceModel.fromMap(Map<String, dynamic> map, List<OpeningBalanceLineModel> lines) {
    return OpeningBalanceModel(
      id: map['id'] as int?,
      number: map['number']?.toString() ?? '',
      entryDate: DateTime.fromMillisecondsSinceEpoch((map['date'] as int) * 1000),
      description: map['statement'] as String?,
      notes: map['extra_properties'] as String?,
      currencyId: map['currency_id'] as int? ?? 1,
      currencyCode: map['currency_code'] as String? ?? 'SAR',
      status: map['status'] as int? ?? 0,
      isPosted: (map['status'] as int? ?? 0) == 2, // status 2 = posted
      totalDebit: (map['debit_amount'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (map['credit_amount'] as num?)?.toDouble() ?? 0.0,
      lines: lines,
      creatorId: map['creator_id'] as int?,
      creationTime: map['creation_time'] as int?,
      lastModificationTime: map['last_modification_time'] as int?,
    );
  }

  /// Converts model to opening_entries table row
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'number': number,
      'date': entryDate.millisecondsSinceEpoch ~/ 1000,
      'statement': description ?? 'رصيد افتتاحي',
      'extra_properties': notes,
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'status': isPosted ? 2 : status,
      'debit_amount': totalDebit,
      'debit_local_amount': totalDebit,
      'credit_amount': totalCredit,
      'credit_local_amount': totalCredit,
      'exchange_rate': 1.0,
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

  /// Creates model from opening_entry_lines table row
  /// The table uses 'amount' and 'type' (1=Debit, 2=Credit)
  factory OpeningBalanceLineModel.fromMap(Map<String, dynamic> map) {
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final type = map['type'] as int? ?? 1;
    
    return OpeningBalanceLineModel(
      id: map['id'] as int?,
      lineNumber: map['line_number'] as int? ?? 0,
      accountId: map['account_id'] as int,
      accountCode: map['account_code'] as String? ?? '',
      accountName: map['account_name'] as String? ?? '',
      currencyId: map['currency_id'] as int? ?? 1,
      currencyCode: map['currency_code'] as String? ?? 'SAR',
      debit: type == 1 ? amount : 0.0,
      credit: type == 2 ? amount : 0.0,
      notes: map['statement'] as String?,
    );
  }

  /// Converts model to opening_entry_lines table row
  /// Uses 'amount' and 'type' (1=Debit, 2=Credit) format
  Map<String, dynamic> toMap(int openingEntryId) {
    // Determine type and amount based on debit/credit
    final int type = debit > 0 ? 1 : 2;
    final double amount = debit > 0 ? debit : credit;
    
    return {
      if (id != null) 'id': id,
      'opening_entry_id': openingEntryId,
      'account_id': accountId,
      'amount': amount,
      'local_amount': amount,
      'type': type,
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'exchange_rate': 1.0,
      'statement': notes ?? '',
      'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
