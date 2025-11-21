# Account Limits System - Usage Guide

## Overview
The Account Limits System ensures that all financial operations in the app respect the defined account limits. It automatically checks limits before any transaction and prevents operations that would exceed the defined thresholds.

## Features
- ✅ Automatic limit checking before transactions
- ✅ Real-time usage tracking
- ✅ Warning notifications at 70% usage
- ✅ Critical alerts at 90% usage
- ✅ Multi-currency support
- ✅ Detailed violation messages
- ✅ Usage history logging

## Database Tables
- `account_limits` - Stores limit definitions
- `account_limit_logs` - Tracks all usage updates

## How It Works

### 1. Setting Account Limits
Account limits are defined per account and currency combination:
```dart
final limit = AccountLimitEntity(
  accountId: 123,
  currencyId: 1,
  debitLimit: 100000,
  creditLimit: 50000,
);
```

### 2. Automatic Checking
The system automatically checks limits when:
- Creating journal entries
- Saving invoices (sales/purchases)
- Processing payments/receipts
- Making any financial transaction

### 3. Integration in Cubits

#### Step 1: Add the Mixin
```dart
class YourCubit extends Cubit<YourState> with AccountLimitMixin {
  final AccountLimitService accountLimitService;
  
  YourCubit({required this.accountLimitService}) : super(InitialState()) {
    initializeLimitChecker(accountLimitService);
  }
}
```

#### Step 2: Check Before Operations
```dart
Future<void> saveTransaction(BuildContext context) async {
  // Check limits first
  final canSave = await canSaveJournalEntry(
    lines: [
      JournalEntryLineValidation(
        accountId: 123,
        currencyId: 1,
        debitAmount: 1000,
        creditAmount: 0,
      ),
    ],
    context: context,
  );
  
  if (!canSave) {
    return; // Dialog will be shown automatically
  }
  
  // Proceed with saving
  // ...
}
```

#### Step 3: Update Usage After Success
```dart
// After successful save
await updateAccountUsage(
  lines: [
    JournalEntryLineValidation(
      accountId: 123,
      currencyId: 1,
      debitAmount: 1000,
      creditAmount: 0,
    ),
  ],
);
```

## Usage Levels

### Safe (< 70%)
- Normal operations
- No warnings

### Warning (70-89%)
- Yellow indicators
- Warning notifications
- Operations still allowed

### Critical (≥ 90%)
- Red indicators
- Critical alerts
- Operations still allowed but strongly warned

## Error Handling

When a limit is exceeded, the system:
1. Prevents the transaction
2. Shows a detailed error dialog with:
   - Account name
   - Requested amount
   - Available amount
   - Specific violations

## Example Integration

### In Sales Invoice
```dart
// Before saving invoice
final canSave = await canSaveInvoice(
  accountId: customerAccountId,
  totalAmount: invoice.total,
  currencyId: invoice.currencyId,
  invoiceType: InvoiceType.sales,
  context: context,
);

if (canSave) {
  // Save invoice
  await saveInvoice(invoice);
  
  // Update usage
  await updateAccountUsage(...);
  
  // Check warnings
  await checkAccountWarnings(context);
}
```

### In Journal Entry
```dart
// Validate all lines
final lines = journalEntry.lines.map((line) => 
  JournalEntryLineValidation(
    accountId: line.accountId,
    currencyId: line.currencyId,
    debitAmount: line.debit,
    creditAmount: line.credit,
  )
).toList();

final canSave = await canSaveJournalEntry(
  lines: lines,
  context: context,
);
```

## Managing Limits

### Create/Update Limit
```dart
final limitService = getIt<AccountLimitService>();
await limitService.saveAccountLimit(limitEntity);
```

### Check Current Usage
```dart
final result = await limitService.getAccountLimit(
  accountId: 123,
  currencyId: 1,
);
```

### Reset Usage (Period End)
```dart
await limitService.resetAccountUsage(
  accountId: 123,
  currencyId: 1,
);
```

### Get Accounts Near Limit
```dart
final result = await limitService.getAccountsNearLimit();
```

## UI Components

The system provides automatic UI feedback:
- **Error Dialogs**: When limits are exceeded
- **Warning Dialogs**: When accounts are near limits
- **Progress Indicators**: Show usage percentages
- **Color Coding**: Green (safe), Yellow (warning), Red (critical)

## Best Practices

1. **Always check limits before operations**
   - Use the mixin methods for consistency
   - Don't bypass the checking system

2. **Update usage immediately after success**
   - Ensures accurate tracking
   - Prevents race conditions

3. **Show warnings proactively**
   - Call `checkAccountWarnings` after operations
   - Inform users before they hit limits

4. **Handle multi-currency properly**
   - Each currency has separate limits
   - Check the correct currency for each operation

5. **Log important operations**
   - System automatically logs usage updates
   - Review logs for audit purposes

## Troubleshooting

### Limit not enforced
- Check if `AccountLimitMixin` is initialized
- Verify limit is active in database
- Ensure correct account/currency IDs

### Wrong usage calculation
- Check for uncommitted transactions
- Verify all operations update usage
- Review account_limit_logs table

### Performance issues
- Use batch validation for multiple lines
- Cache frequently accessed limits
- Index account_id and currency_id columns

## Security Considerations

- Only authorized users should modify limits
- Log all limit changes for audit
- Implement approval workflow for limit increases
- Regular review of usage patterns

## Future Enhancements

- [ ] Time-based limits (daily, monthly)
- [ ] Department-wise limits
- [ ] Automatic limit adjustment based on history
- [ ] Email/SMS notifications
- [ ] Limit approval workflow
- [ ] Dashboard for limit monitoring
