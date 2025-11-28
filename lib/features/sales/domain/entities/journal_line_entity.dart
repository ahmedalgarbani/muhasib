import 'package:equatable/equatable.dart';

class JournalLineEntity extends Equatable {
  final int? id;
  final int accountId;
  final double debit;
  final double credit;
  final String? description;
  final String? referenceType;
  final int? referenceId;
  final int? partnerId;
  final String? partnerType;
  final int? currencyId;
  final double? exchangeRate;
  final int? creationTime;

  const JournalLineEntity({
    this.id,
    required this.accountId,
    required this.debit,
    required this.credit,
    this.description,
    this.referenceType,
    this.referenceId,
    this.partnerId,
    this.partnerType,
    this.currencyId,
    this.exchangeRate,
    this.creationTime,
  });

  @override
  List<Object?> get props => [
        id,
        accountId,
        debit,
        credit,
        description,
        referenceType,
        referenceId,
        partnerId,
        partnerType,
        currencyId,
        exchangeRate,
        creationTime,
      ];

  JournalLineEntity copyWith({
    int? id,
    int? accountId,
    double? debit,
    double? credit,
    String? description,
    String? referenceType,
    int? referenceId,
    int? partnerId,
    String? partnerType,
    int? currencyId,
    double? exchangeRate,
    int? creationTime,
  }) {
    return JournalLineEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      partnerId: partnerId ?? this.partnerId,
      partnerType: partnerType ?? this.partnerType,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      creationTime: creationTime ?? this.creationTime,
    );
  }
}
