# Account Connect Validation System

## Overview
The Account Connect Validation System ensures that all required account connections are properly configured before allowing financial operations. This prevents errors and ensures data integrity by validating that system accounts (like Banks, Customers, Suppliers) are linked to actual chart of accounts entries.

## Why Account Connections Matter

Account connections link system operations to the correct general ledger accounts:
- **Sales** → Links to Sales Revenue account
- **Customers** → Links to Accounts Receivable
- **Suppliers** → Links to Accounts Payable
- **Banks** → Links to Bank accounts
- **Inventory** → Links to Inventory Asset account

Without these connections, the system cannot properly record transactions in the general ledger.

## Account Connection Types

| Type | Name (Arabic) | Name (English) | Purpose |
|------|--------------|----------------|---------|
| 0 | البنوك | Banks | Bank transactions |
| 1 | الصناديق | Cash | Cash transactions |
| 2 | العملاء | Customers | Customer receivables |
| 3 | الموردون | Suppliers | Supplier payables |
| 4 | الضرائب | Taxes | Tax calculations |
| 5 | المخزون | Inventory | Stock valuation |
| 6 | البضاعة | Goods | Merchandise |
| 7 | المبيعات | Sales | Revenue recognition |
| 8 | الخصم المسموح به | Discount Allowed | Sales discounts |
| 9 | الخصم المكتسب | Discount Received | Purchase discounts |
| 10 | المشتريات | Purchases | Purchase expenses |

## Features

✅ **Pre-Operation Validation**: Checks connections before any transaction
✅ **Automatic Seeding**: Default connections created on first run
✅ **Caching**: 5-minute cache for performance
✅ **Operation-Specific Validation**: Different requirements for different operations
✅ **User-Friendly Errors**: Clear messages about what needs to be connected
✅ **Direct Navigation**: Links to connection setup page from error dialogs

## How It Works

### 1. System Initialization
When the database is first created, the seeder automatically creates default connections:
```dart
// Default connections created by seeder
Banks → النقدية في البنوك (cId: 1100)
Cash → الصندوق (cId: 1101)
Customers → العملاء (cId: 1200)
Suppliers → الموردون (cId: 2100)
// ... etc
```

### 2. Operation Validation
Before each operation, the system checks required connections:

#### Sales Operation
- ✓ Customers account connected
- ✓ Sales account connected

#### Purchase Operation
- ✓ Suppliers account connected
- ✓ Purchases account connected

#### Payment Operation
- ✓ Banks account connected
- ✓ Cash account connected

#### Inventory Operation
- ✓ Inventory account connected
- ✓ Goods account connected

### 3. Validation Process
```dart
// 1. Check connections
if (!await validateSalesConnections(context)) {
  // Shows error dialog with missing connections
  return;
}

// 2. Get connected account IDs
final customersAccountId = await getConnectedAccountId(2);
final salesAccountId = await getConnectedAccountId(7);

// 3. Proceed with operation
await saveInvoice(...);
```

## Integration Guide

### Step 1: Add the Mixin to Your Cubit
```dart
class YourCubit extends Cubit<YourState> 
    with AccountConnectValidationMixin {
  
  final AccountConnectValidator validator;
  
  YourCubit({required this.validator}) : super(InitialState()) {
    initializeConnectValidator(validator);
  }
}
```

### Step 2: Validate Before Operations
```dart
// For sales
if (!await validateSalesConnections(context)) {
  return; // Dialog shown automatically
}

// For purchases
if (!await validatePurchaseConnections(context)) {
  return;
}

// For payments
if (!await validatePaymentConnections(context)) {
  return;
}

// For inventory
if (!await validateInventoryConnections(context)) {
  return;
}
```

### Step 3: Get Connected Account IDs
```dart
// Get the actual account ID for a connection type
final accountId = await getConnectedAccountId(2); // Customers
if (accountId == null) {
  // Handle missing connection
}
```

### Step 4: Check System Readiness
```dart
// On app startup or settings page
await checkConnectionStatus(context);
```

## Error Handling

When connections are missing, the system shows:
1. **Error Dialog** with:
   - List of missing connections
   - Explanation of why they're needed
   - Button to navigate to connection setup

2. **Status Dialog** showing:
   - Completion percentage
   - Progress bar
   - List of unconnected accounts

## UI Components

### Connection Status Page (`account_link_page.dart`)
- Shows all connection types
- Visual indicators for connected/unconnected
- Tap to link/unlink accounts
- Search functionality
- Real-time status updates

### Error Dialogs
- Clear error messages
- List of missing connections
- Direct navigation to fix issues
- Progress indicators

## Database Schema

### account_connects Table
```sql
CREATE TABLE account_connects (
  id INTEGER PRIMARY KEY,
  account_connect_type INTEGER,  -- Type (0-10)
  c_id INTEGER,                  -- Connected account cId
  creation_time INTEGER,
  last_modification_time INTEGER
);
```

## Best Practices

### 1. Always Validate Before Operations
```dart
// ✅ Good
if (await validateSalesConnections(context)) {
  await saveInvoice();
}

// ❌ Bad - No validation
await saveInvoice(); // May fail if not connected
```

### 2. Cache Account IDs
```dart
// Cache frequently used IDs
int? _customersAccountId;

Future<int?> getCustomersAccountId() async {
  _customersAccountId ??= await getConnectedAccountId(2);
  return _customersAccountId;
}
```

### 3. Check on Startup
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<YourCubit>().checkConnectionStatus(context);
  });
}
```

### 4. Handle Missing Connections Gracefully
```dart
final accountId = await getConnectedAccountId(2);
if (accountId == null) {
  // Show message to user
  showDialog(...);
  return;
}
// Continue with operation
```

## Troubleshooting

### Problem: "حسابات غير مرتبطة" error
**Solution**: Go to Settings → Account Connections and link the required accounts

### Problem: Seeder didn't create connections
**Solution**: Check if accounts exist with the expected cIds in the accounts table

### Problem: Connection not found after linking
**Solution**: Clear the cache:
```dart
validator.clearCache();
```

### Problem: Wrong account linked
**Solution**: Unlink and relink from the Account Connections page

## Security Considerations

- Only administrators should modify account connections
- Log all connection changes for audit
- Validate connections cannot be deleted if transactions exist
- Backup connection settings before major changes

## Performance Optimization

- **Caching**: 5-minute cache reduces database queries
- **Batch Validation**: Check multiple connections at once
- **Lazy Loading**: Only load connections when needed
- **Indexed Queries**: account_connect_type is indexed

## Future Enhancements

- [ ] Role-based connection management
- [ ] Connection templates for different business types
- [ ] Automatic connection suggestions based on usage
- [ ] Connection validation reports
- [ ] Multi-company connection profiles
- [ ] API for external connection management

## Complete Example

```dart
// Complete validation flow
class InvoiceService {
  Future<bool> createSalesInvoice(Invoice invoice) async {
    // 1. Validate connections
    if (!await validateSalesConnections(context)) {
      return false;
    }
    
    // 2. Get account IDs
    final customersId = await getConnectedAccountId(2);
    final salesId = await getConnectedAccountId(7);
    
    // 3. Check account limits
    if (!await checkAccountLimit(customersId, invoice.total)) {
      return false;
    }
    
    // 4. Create journal entries
    await createJournalEntry([
      JournalLine(customersId, debit: invoice.total),
      JournalLine(salesId, credit: invoice.total),
    ]);
    
    // 5. Save invoice
    await saveInvoice(invoice);
    
    return true;
  }
}
```

## Summary

The Account Connect Validation System ensures:
- ✅ All operations have proper account mappings
- ✅ Transactions are recorded in correct GL accounts
- ✅ System integrity is maintained
- ✅ Users are guided to fix configuration issues
- ✅ Performance is optimized with caching
