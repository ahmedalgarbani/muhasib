import 'package:equatable/equatable.dart';

class OpeningBalanceEntity extends Equatable {
  final int? id;
  final String number;
  final DateTime entryDate;
  final String? description;
  final String? notes;
  final int currencyId;
  final String currencyCode;
  final int status;
  final bool isPosted;
  final double totalDebit;
  final double totalCredit;
  final List<OpeningBalanceLineEntity> lines;
  final int? creatorId;
  final int? creationTime;
  final int? lastModificationTime;

  const OpeningBalanceEntity({
    this.id,
    required this.number,
    required this.entryDate,
    this.description,
    this.notes,
    required this.currencyId,
    required this.currencyCode,
    this.status = 0,
    this.isPosted = false,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
    this.creatorId,
    this.creationTime,
    this.lastModificationTime,
  });

  double get difference => totalDebit - totalCredit;
  bool get isBalanced => difference == 0;

  OpeningBalanceEntity copyWith({
    int? id,
    String? number,
    DateTime? entryDate,
    String? description,
    String? notes,
    int? currencyId,
    String? currencyCode,
    int? status,
    bool? isPosted,
    double? totalDebit,
    double? totalCredit,
    List<OpeningBalanceLineEntity>? lines,
    int? creatorId,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return OpeningBalanceEntity(
      id: id ?? this.id,
      number: number ?? this.number,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      currencyId: currencyId ?? this.currencyId,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      isPosted: isPosted ?? this.isPosted,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      lines: lines ?? this.lines,
      creatorId: creatorId ?? this.creatorId,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        entryDate,
        description,
        notes,
        currencyId,
        currencyCode,
        status,
        isPosted,
        totalDebit,
        totalCredit,
        lines,
        creatorId,
        creationTime,
        lastModificationTime,
      ];
}

class OpeningBalanceLineEntity extends Equatable {
  final int? id;
  final int lineNumber;
  final int accountId;
  final String accountCode;
  final String accountName;
  final int currencyId;
  final String currencyCode;
  final double debit;
  final double credit;
  final String? notes;

  const OpeningBalanceLineEntity({
    this.id,
    required this.lineNumber,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.currencyId,
    required this.currencyCode,
    required this.debit,
    required this.credit,
    this.notes,
  });

  OpeningBalanceLineEntity copyWith({
    int? id,
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
    return OpeningBalanceLineEntity(
      id: id ?? this.id,
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
