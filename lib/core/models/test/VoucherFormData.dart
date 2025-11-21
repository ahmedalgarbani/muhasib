
class VoucherFormData {
  String number;
  String date;
  String account;
  String notes;
  String amount;
  String currency;
  String bank;
  String accountNumber;
  String senderName;
  String recipientName;
  String commissionAmount;
  String commissionCurrency;

  VoucherFormData({
    this.number = '1',
    this.date = '17-10-2025',
    this.account = '',
    this.notes = '',
    this.amount = '',
    this.currency = 'USD',
    this.bank = '',
    this.accountNumber = '',
    this.senderName = '',
    this.recipientName = '',
    this.commissionAmount = '',
    this.commissionCurrency = 'USD',
  });

  VoucherFormData copyWith({
    String? number,
    String? date,
    String? account,
    String? notes,
    String? amount,
    String? currency,
    String? bank,
    String? accountNumber,
    String? senderName,
    String? recipientName,
    String? commissionAmount,
    String? commissionCurrency,
  }) {
    return VoucherFormData(
      number: number ?? this.number,
      date: date ?? this.date,
      account: account ?? this.account,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      bank: bank ?? this.bank,
      accountNumber: accountNumber ?? this.accountNumber,
      senderName: senderName ?? this.senderName,
      recipientName: recipientName ?? this.recipientName,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      commissionCurrency: commissionCurrency ?? this.commissionCurrency,
    );
  }
}

enum VoucherType { expense, receipt }

enum PaymentMethod { cash, bankTransfer }
