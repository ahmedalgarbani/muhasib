import 'package:equatable/equatable.dart';

class JournalEntryLineEntity extends Equatable {
  final int? id;
  final int? journalEntryId;
  final int lineNumber;
  final int? accountId;
  final String? accountCode;
  final String accountName;
  final int? currencyId;
  final String currencyCode;
  final double debit;
  final double credit;
  final String? notes;

  const JournalEntryLineEntity({
    this.id,
    this.journalEntryId,
    required this.lineNumber,
    this.accountId,
    this.accountCode,
    required this.accountName,
    this.currencyId,
    required this.currencyCode,
    required this.debit,
    required this.credit,
    this.notes,
  });

  JournalEntryLineEntity copyWith({
    int? id,
    int? journalEntryId,
    int? lineNumber,
    int? accountId,
    String? accountCode,
    String? accountName,
    int? currencyId,
    String? currencyCode,
    double? debit,
    double? credit,
    String? notes,
  }) {
    return JournalEntryLineEntity(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      lineNumber: lineNumber ?? this.lineNumber,
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      currencyId: currencyId ?? this.currencyId,
      currencyCode: currencyCode ?? this.currencyCode,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        journalEntryId,
        lineNumber,
        accountId,
        accountCode,
        accountName,
        currencyId,
        currencyCode,
        debit,
        credit,
        notes,
      ];
}

class JournalEntryEntity extends Equatable {
  final int? id;
  final String number;
  final DateTime entryDate;
  final String? description;
  final String? referenceNumber;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final int status;
  final bool isPosted;
  final double totalDebit;
  final double totalCredit;
  final double difference;
  final List<JournalEntryLineEntity> lines;

  const JournalEntryEntity({
    this.id,
    required this.number,
    required this.entryDate,
    this.description,
    this.referenceNumber,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.status = 0,
    this.isPosted = false,
    required this.totalDebit,
    required this.totalCredit,
    required this.difference,
    this.lines = const [],
  });

  JournalEntryEntity copyWith({
    int? id,
    String? number,
    DateTime? entryDate,
    String? description,
    String? referenceNumber,
    String? referenceType,
    int? referenceId,
    String? notes,
    int? status,
    bool? isPosted,
    double? totalDebit,
    double? totalCredit,
    double? difference,
    List<JournalEntryLineEntity>? lines,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isPosted: isPosted ?? this.isPosted,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      difference: difference ?? this.difference,
      lines: lines ?? this.lines,
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        entryDate,
        description,
        referenceNumber,
        referenceType,
        referenceId,
        notes,
        status,
        isPosted,
        totalDebit,
        totalCredit,
        difference,
        lines,
      ];
}
