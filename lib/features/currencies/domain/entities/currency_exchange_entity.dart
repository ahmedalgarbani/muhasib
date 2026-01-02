import 'package:equatable/equatable.dart';

/// Entity representing a currency exchange transaction
class CurrencyExchangeEntity extends Equatable {
  final int? id;
  final int number;
  final DateTime date;
  final String statement;
  
  // Credit side (from currency - being sold)
  final int creditAccountId;
  final int creditCurrencyId;
  final String creditCurrencyCode;
  final double creditAmount;
  final double creditExchangeRate;
  final double creditLocalAmount;
  
  // Debit side (to currency - being bought)
  final int debitAccountId;
  final int debitCurrencyId;
  final String debitCurrencyCode;
  final double debitAmount;
  final double debitExchangeRate;
  final double debitLocalAmount;
  
  // Exchange rate difference (profit/loss)
  final double exchangeRateDifference;
  final int? exchangeDifferenceAccountId;
  
  // Journal entry reference
  final int? journalEntryId;
  
  // Metadata
  final int? creatorId;
  final int? lastModifierId;
  final int? creationTime;
  final int? lastModificationTime;
  final String? notes;
  final int status; // 0 = draft, 1 = posted
  
  const CurrencyExchangeEntity({
    this.id,
    required this.number,
    required this.date,
    required this.statement,
    required this.creditAccountId,
    required this.creditCurrencyId,
    required this.creditCurrencyCode,
    required this.creditAmount,
    required this.creditExchangeRate,
    required this.creditLocalAmount,
    required this.debitAccountId,
    required this.debitCurrencyId,
    required this.debitCurrencyCode,
    required this.debitAmount,
    required this.debitExchangeRate,
    required this.debitLocalAmount,
    this.exchangeRateDifference = 0.0,
    this.exchangeDifferenceAccountId,
    this.journalEntryId,
    this.creatorId,
    this.lastModifierId,
    this.creationTime,
    this.lastModificationTime,
    this.notes,
    this.status = 0,
  });

  @override
  List<Object?> get props => [
    id,
    number,
    date,
    statement,
    creditAccountId,
    creditCurrencyId,
    creditCurrencyCode,
    creditAmount,
    creditExchangeRate,
    creditLocalAmount,
    debitAccountId,
    debitCurrencyId,
    debitCurrencyCode,
    debitAmount,
    debitExchangeRate,
    debitLocalAmount,
    exchangeRateDifference,
    exchangeDifferenceAccountId,
    journalEntryId,
    creatorId,
    lastModifierId,
    creationTime,
    lastModificationTime,
    notes,
    status,
  ];

  CurrencyExchangeEntity copyWith({
    int? id,
    int? number,
    DateTime? date,
    String? statement,
    int? creditAccountId,
    int? creditCurrencyId,
    String? creditCurrencyCode,
    double? creditAmount,
    double? creditExchangeRate,
    double? creditLocalAmount,
    int? debitAccountId,
    int? debitCurrencyId,
    String? debitCurrencyCode,
    double? debitAmount,
    double? debitExchangeRate,
    double? debitLocalAmount,
    double? exchangeRateDifference,
    int? exchangeDifferenceAccountId,
    int? journalEntryId,
    int? creatorId,
    int? lastModifierId,
    int? creationTime,
    int? lastModificationTime,
    String? notes,
    int? status,
  }) {
    return CurrencyExchangeEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      creditAccountId: creditAccountId ?? this.creditAccountId,
      creditCurrencyId: creditCurrencyId ?? this.creditCurrencyId,
      creditCurrencyCode: creditCurrencyCode ?? this.creditCurrencyCode,
      creditAmount: creditAmount ?? this.creditAmount,
      creditExchangeRate: creditExchangeRate ?? this.creditExchangeRate,
      creditLocalAmount: creditLocalAmount ?? this.creditLocalAmount,
      debitAccountId: debitAccountId ?? this.debitAccountId,
      debitCurrencyId: debitCurrencyId ?? this.debitCurrencyId,
      debitCurrencyCode: debitCurrencyCode ?? this.debitCurrencyCode,
      debitAmount: debitAmount ?? this.debitAmount,
      debitExchangeRate: debitExchangeRate ?? this.debitExchangeRate,
      debitLocalAmount: debitLocalAmount ?? this.debitLocalAmount,
      exchangeRateDifference: exchangeRateDifference ?? this.exchangeRateDifference,
      exchangeDifferenceAccountId: exchangeDifferenceAccountId ?? this.exchangeDifferenceAccountId,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      creatorId: creatorId ?? this.creatorId,
      lastModifierId: lastModifierId ?? this.lastModifierId,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}

/// Entity for exchange rate history tracking
class ExchangeRateHistoryEntity extends Equatable {
  final int? id;
  final int currencyId;
  final double exchangeRate;
  final DateTime effectiveDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;

  const ExchangeRateHistoryEntity({
    this.id,
    required this.currencyId,
    required this.exchangeRate,
    required this.effectiveDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    currencyId,
    exchangeRate,
    effectiveDate,
    endDate,
    notes,
    isActive,
  ];
}
