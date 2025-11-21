import 'package:equatable/equatable.dart';

class AccountLimitEntity extends Equatable {
  final int? id;
  final int accountId;
  final String accountName;
  final String accountCode;
  final int currencyId;
  final String currencyCode;
  final double debitLimit;
  final double creditLimit;
  final double currentDebit;
  final double currentCredit;
  final bool isActive;
  final int? creatorId;
  final int? creationTime;
  final int? lastModificationTime;

  const AccountLimitEntity({
    this.id,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.currencyId,
    required this.currencyCode,
    required this.debitLimit,
    required this.creditLimit,
    this.currentDebit = 0,
    this.currentCredit = 0,
    this.isActive = true,
    this.creatorId,
    this.creationTime,
    this.lastModificationTime,
  });

  double get debitUsagePercentage {
    if (debitLimit == 0) return 0;
    return (currentDebit / debitLimit * 100).clamp(0, 100);
  }

  double get creditUsagePercentage {
    if (creditLimit == 0) return 0;
    return (currentCredit / creditLimit * 100).clamp(0, 100);
  }

  double get maxUsagePercentage {
    return debitUsagePercentage > creditUsagePercentage
        ? debitUsagePercentage
        : creditUsagePercentage;
  }

  double get availableDebit => debitLimit - currentDebit;
  double get availableCredit => creditLimit - currentCredit;

  UsageLevel get usageLevel {
    final max = maxUsagePercentage;
    if (max >= 90) return UsageLevel.critical;
    if (max >= 70) return UsageLevel.warning;
    return UsageLevel.safe;
  }

  bool canAddDebit(double amount) {
    if (!isActive) return false;
    if (debitLimit == 0) return true; // No limit
    return (currentDebit + amount) <= debitLimit;
  }

  bool canAddCredit(double amount) {
    if (!isActive) return false;
    if (creditLimit == 0) return true; // No limit
    return (currentCredit + amount) <= creditLimit;
  }

  AccountLimitEntity copyWith({
    int? id,
    int? accountId,
    String? accountName,
    String? accountCode,
    int? currencyId,
    String? currencyCode,
    double? debitLimit,
    double? creditLimit,
    double? currentDebit,
    double? currentCredit,
    bool? isActive,
    int? creatorId,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return AccountLimitEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      accountCode: accountCode ?? this.accountCode,
      currencyId: currencyId ?? this.currencyId,
      currencyCode: currencyCode ?? this.currencyCode,
      debitLimit: debitLimit ?? this.debitLimit,
      creditLimit: creditLimit ?? this.creditLimit,
      currentDebit: currentDebit ?? this.currentDebit,
      currentCredit: currentCredit ?? this.currentCredit,
      isActive: isActive ?? this.isActive,
      creatorId: creatorId ?? this.creatorId,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        accountCode,
        currencyId,
        currencyCode,
        debitLimit,
        creditLimit,
        currentDebit,
        currentCredit,
        isActive,
        creatorId,
        creationTime,
        lastModificationTime,
      ];
}

enum UsageLevel { safe, warning, critical }

class AccountLimitViolation {
  final AccountLimitEntity limit;
  final double requestedAmount;
  final double availableAmount;
  final bool isDebit;
  final String message;

  const AccountLimitViolation({
    required this.limit,
    required this.requestedAmount,
    required this.availableAmount,
    required this.isDebit,
    required this.message,
  });
}
