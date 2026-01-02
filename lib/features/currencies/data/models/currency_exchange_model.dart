import 'package:muhasib/features/currencies/domain/entities/currency_exchange_entity.dart';

/// Model for currency exchange database operations
class CurrencyExchangeModel extends CurrencyExchangeEntity {
  const CurrencyExchangeModel({
    super.id,
    required super.number,
    required super.date,
    required super.statement,
    required super.creditAccountId,
    required super.creditCurrencyId,
    required super.creditCurrencyCode,
    required super.creditAmount,
    required super.creditExchangeRate,
    required super.creditLocalAmount,
    required super.debitAccountId,
    required super.debitCurrencyId,
    required super.debitCurrencyCode,
    required super.debitAmount,
    required super.debitExchangeRate,
    required super.debitLocalAmount,
    super.exchangeRateDifference,
    super.exchangeDifferenceAccountId,
    super.journalEntryId,
    super.creatorId,
    super.lastModifierId,
    super.creationTime,
    super.lastModificationTime,
    super.notes,
    super.status,
  });

  factory CurrencyExchangeModel.fromJson(Map<String, dynamic> json) {
    return CurrencyExchangeModel(
      id: json['id'] as int?,
      number: json['number'] as int,
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as int) * 1000),
      statement: json['statement'] as String,
      creditAccountId: json['credit_account_id'] as int,
      creditCurrencyId: json['credit_currency_id'] as int,
      creditCurrencyCode: json['credit_currency_code'] as String,
      creditAmount: (json['credit_amount'] as num).toDouble(),
      creditExchangeRate: (json['credit_exchange_rate'] as num).toDouble(),
      creditLocalAmount: (json['credit_local_amount'] as num).toDouble(),
      debitAccountId: json['debit_account_id'] as int,
      debitCurrencyId: json['debit_currency_id'] as int,
      debitCurrencyCode: json['debit_currency_code'] as String,
      debitAmount: (json['debit_amount'] as num).toDouble(),
      debitExchangeRate: (json['debit_exchange_rate'] as num).toDouble(),
      debitLocalAmount: (json['debit_local_amount'] as num).toDouble(),
      exchangeRateDifference: (json['exchange_rate_difference'] as num?)?.toDouble() ?? 0.0,
      exchangeDifferenceAccountId: json['exchange_difference_account_id'] as int?,
      journalEntryId: json['journal_entry_id'] as int?,
      creatorId: json['creator_id'] as int?,
      lastModifierId: json['last_modifier_id'] as int?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
      notes: json['notes'] as String?,
      status: json['status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'number': number,
      'date': date.millisecondsSinceEpoch ~/ 1000,
      'statement': statement,
      'credit_account_id': creditAccountId,
      'credit_currency_id': creditCurrencyId,
      'credit_currency_code': creditCurrencyCode,
      'credit_amount': creditAmount,
      'credit_exchange_rate': creditExchangeRate,
      'credit_local_amount': creditLocalAmount,
      'debit_account_id': debitAccountId,
      'debit_currency_id': debitCurrencyId,
      'debit_currency_code': debitCurrencyCode,
      'debit_amount': debitAmount,
      'debit_exchange_rate': debitExchangeRate,
      'debit_local_amount': debitLocalAmount,
      'exchange_rate_difference': exchangeRateDifference,
      'exchange_difference_account_id': exchangeDifferenceAccountId,
      'journal_entry_id': journalEntryId,
      'creator_id': creatorId ?? 1,
      'last_modifier_id': lastModifierId ?? 1,
      'notes': notes,
      'status': status,
    };
    
    if (creationTime != null) {
      map['creation_time'] = creationTime;
    }
    if (lastModificationTime != null) {
      map['last_modification_time'] = lastModificationTime;
    }
    
    return map;
  }

  factory CurrencyExchangeModel.fromEntity(CurrencyExchangeEntity entity) {
    return CurrencyExchangeModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      statement: entity.statement,
      creditAccountId: entity.creditAccountId,
      creditCurrencyId: entity.creditCurrencyId,
      creditCurrencyCode: entity.creditCurrencyCode,
      creditAmount: entity.creditAmount,
      creditExchangeRate: entity.creditExchangeRate,
      creditLocalAmount: entity.creditLocalAmount,
      debitAccountId: entity.debitAccountId,
      debitCurrencyId: entity.debitCurrencyId,
      debitCurrencyCode: entity.debitCurrencyCode,
      debitAmount: entity.debitAmount,
      debitExchangeRate: entity.debitExchangeRate,
      debitLocalAmount: entity.debitLocalAmount,
      exchangeRateDifference: entity.exchangeRateDifference,
      exchangeDifferenceAccountId: entity.exchangeDifferenceAccountId,
      journalEntryId: entity.journalEntryId,
      creatorId: entity.creatorId,
      lastModifierId: entity.lastModifierId,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
      notes: entity.notes,
      status: entity.status,
    );
  }

  CurrencyExchangeEntity toEntity() {
    return CurrencyExchangeEntity(
      id: id,
      number: number,
      date: date,
      statement: statement,
      creditAccountId: creditAccountId,
      creditCurrencyId: creditCurrencyId,
      creditCurrencyCode: creditCurrencyCode,
      creditAmount: creditAmount,
      creditExchangeRate: creditExchangeRate,
      creditLocalAmount: creditLocalAmount,
      debitAccountId: debitAccountId,
      debitCurrencyId: debitCurrencyId,
      debitCurrencyCode: debitCurrencyCode,
      debitAmount: debitAmount,
      debitExchangeRate: debitExchangeRate,
      debitLocalAmount: debitLocalAmount,
      exchangeRateDifference: exchangeRateDifference,
      exchangeDifferenceAccountId: exchangeDifferenceAccountId,
      journalEntryId: journalEntryId,
      creatorId: creatorId,
      lastModifierId: lastModifierId,
      creationTime: creationTime,
      lastModificationTime: lastModificationTime,
      notes: notes,
      status: status,
    );
  }
}

/// Model for exchange rate history
class ExchangeRateHistoryModel {
  final int? id;
  final int currencyId;
  final double exchangeRate;
  final DateTime effectiveDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final int? creationTime;
  final int? lastModificationTime;

  const ExchangeRateHistoryModel({
    this.id,
    required this.currencyId,
    required this.exchangeRate,
    required this.effectiveDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.creationTime,
    this.lastModificationTime,
  });

  factory ExchangeRateHistoryModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateHistoryModel(
      id: json['id'] as int?,
      currencyId: json['currency_id'] as int,
      exchangeRate: (json['exchange_rate'] as num).toDouble(),
      effectiveDate: DateTime.fromMillisecondsSinceEpoch((json['effective_date'] as int) * 1000),
      endDate: json['end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((json['end_date'] as int) * 1000) 
          : null,
      notes: json['notes'] as String?,
      isActive: (json['is_active'] as int?) == 1,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'effective_date': effectiveDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'creation_time': creationTime ?? now,
      'last_modification_time': lastModificationTime ?? now,
    };
  }
}
