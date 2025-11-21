# Purchases Feature Implementation

## Overview
The Purchases feature has been implemented following clean architecture principles, mirroring the Sales feature structure but with purchase-specific business logic.

## Architecture

### Domain Layer
```
domain/
├── repositories/
│   └── purchase_repository.dart
├── usecases/
│   ├── get_purchases.dart
│   └── create_purchase.dart
└── templates/
    ├── purchases_accounting_template.dart
    └── purchases_accounting_template_simple.dart
```

### Data Layer
```
data/
├── datasources/
│   └── purchase_local_datasource.dart (if needed)
├── models/
│   └── (reuses InvoiceModel from sales)
└── repositories/
    └── purchase_repository_impl.dart
```

### Presentation Layer
```
presentation/
├── cubit/
│   ├── purchases_cubit.dart
│   └── purchases_state.dart
├── pages/
│   ├── purchases_page.dart
│   ├── purchase_form_page.dart
│   └── purchase_detail_page.dart
└── widgets/
    └── purchase_card.dart
```

## Database Schema

### Purchases use the existing `invoices` table:
```sql
-- Purchase Invoice
invoice_type = 2  -- Purchase Invoice
invoice_trans_type = 0 (Cash) or 1 (Credit)

-- Purchase Order
invoice_type = 3
invoice_trans_type = 1

-- Purchase Return
invoice_type = 5
invoice_trans_type = 1
```

## Key Features

### 1. Purchase Invoice Creation
- Select supplier from suppliers list
- Add products with quantities and prices
- Calculate totals with tax
- Support cash and credit purchases
- Auto-generate journal entries

### 2. Purchase Orders
- Create purchase orders for future delivery
- Convert orders to invoices when goods arrive
- Track order status

### 3. Purchase Returns
- Return defective or unwanted items
- Link to original purchase invoice
- Generate reverse journal entries
- Update inventory and supplier balance

### 4. Accounting Integration

#### Cash Purchase Journal Entry:
```
Debit: Inventory/Purchases Account
Credit: Cash/Bank Account
```

#### Credit Purchase Journal Entry:
```
Debit: Inventory/Purchases Account  
Credit: Accounts Payable/Supplier Account
```

#### Purchase Return Journal Entry:
```
Debit: Accounts Payable/Supplier Account
Credit: Inventory/Purchases Account
```

## Business Logic

### When Creating Purchase Invoice:
1. **Validate** supplier exists and is active
2. **Check** product availability and pricing
3. **Calculate** totals including tax
4. **Update** inventory quantities (increase)
5. **Update** supplier balance (if credit purchase)
6. **Generate** journal entries
7. **Save** invoice to database

### When Creating Purchase Return:
1. **Validate** original invoice exists
2. **Check** returned quantities don't exceed purchased
3. **Calculate** return amount
4. **Update** inventory (decrease)
5. **Update** supplier balance (decrease payable)
6. **Generate** reverse journal entries
7. **Save** return invoice

## API Methods

### PurchaseRepository
```dart
// Purchase Invoices
Future<Either<Failure, List<InvoiceEntity>>> getPurchaseInvoices();
Future<Either<Failure, InvoiceEntity>> getPurchaseInvoice(int id);
Future<Either<Failure, int>> createPurchaseInvoice(InvoiceEntity invoice);
Future<Either<Failure, void>> updatePurchaseInvoice(InvoiceEntity invoice);
Future<Either<Failure, void>> deletePurchaseInvoice(int id);

// Purchase Orders
Future<Either<Failure, List<InvoiceEntity>>> getPurchaseOrders();
Future<Either<Failure, int>> createPurchaseOrder(InvoiceEntity order);
Future<Either<Failure, int>> convertOrderToInvoice(int orderId, InvoiceEntity invoice);

// Purchase Returns
Future<Either<Failure, List<InvoiceEntity>>> getPurchaseReturns();
Future<Either<Failure, int>> createPurchaseReturn(InvoiceEntity returnInvoice, int parentInvoiceId);
```

### PurchasesCubit Methods
```dart
// Load data
loadPurchaseInvoices()
loadPurchaseOrders()
loadPurchaseReturns()

// Create operations
createPurchaseInvoice(InvoiceEntity invoice)
createPurchaseOrder(InvoiceEntity order)
createPurchaseReturn(InvoiceEntity returnInvoice, int parentInvoiceId)

// Update/Delete
updatePurchaseInvoice(InvoiceEntity invoice)
deletePurchaseInvoice(int id)

// Convert
convertOrderToInvoice(int orderId, InvoiceEntity invoice)

// Search
searchPurchases(String query)
```

## States

### PurchasesState
- `PurchasesInitial` - Initial state
- `PurchasesLoading` - Loading data
- `PurchasesError` - Error occurred
- `PurchaseInvoicesLoaded` - Invoices loaded
- `PurchaseInvoiceCreated` - Invoice created
- `PurchaseInvoiceUpdated` - Invoice updated
- `PurchaseInvoiceDeleted` - Invoice deleted
- `PurchaseOrdersLoaded` - Orders loaded
- `PurchaseOrderCreated` - Order created
- `PurchaseOrderConverted` - Order converted to invoice
- `PurchaseReturnsLoaded` - Returns loaded
- `PurchaseReturnCreated` - Return created

## Integration Points

### 1. With Inventory System
- Updates stock quantities on purchase
- Decreases stock on returns
- Tracks product costs

### 2. With Suppliers Module
- Updates supplier balances
- Tracks payables
- Manages supplier transactions

### 3. With Accounting
- Generates journal entries
- Updates general ledger
- Maintains audit trail

### 4. With Reports
- Purchase reports
- Supplier statements
- Inventory valuation

## UI Components

### Purchase Form Fields
- Invoice Number (auto-generated)
- Date
- Supplier (dropdown)
- Payment Type (Cash/Credit)
- Products List
  - Product
  - Quantity
  - Unit Price
  - Total
- Subtotal
- Tax
- Grand Total
- Notes

### Purchase List View
- Filter by date range
- Filter by supplier
- Filter by status
- Search functionality
- Sort options

## Validation Rules

1. **Supplier**: Must be active and valid
2. **Products**: At least one product required
3. **Quantities**: Must be positive numbers
4. **Prices**: Must be non-negative
5. **Date**: Cannot be future date
6. **Returns**: Cannot exceed original quantity

## Security Considerations

1. **Permissions**:
   - View purchases
   - Create purchases
   - Edit purchases
   - Delete purchases
   - Create returns

2. **Audit Trail**:
   - Track all changes
   - Store user who created/modified
   - Timestamp all operations

## Testing Checklist

- [ ] Create cash purchase invoice
- [ ] Create credit purchase invoice
- [ ] View purchase details
- [ ] Edit purchase invoice
- [ ] Delete purchase invoice
- [ ] Create purchase order
- [ ] Convert order to invoice
- [ ] Create purchase return
- [ ] Search purchases
- [ ] Filter by supplier
- [ ] Filter by date
- [ ] Verify inventory updates
- [ ] Verify supplier balance updates
- [ ] Verify journal entries
- [ ] Test validation rules

## Future Enhancements

1. **Purchase Approval Workflow**
   - Multi-level approvals
   - Budget checking
   - Authorization limits

2. **Advanced Features**
   - Recurring purchases
   - Purchase contracts
   - Price comparisons
   - Vendor ratings

3. **Integration**
   - Barcode scanning
   - Electronic invoicing
   - Supplier portals
   - Payment gateways

## Configuration

### Account Connections Required
- Inventory/Purchases Account
- Cash/Bank Account
- Accounts Payable Account
- Tax Account (if applicable)

### Settings
- Default payment terms
- Tax rates
- Invoice numbering format
- Approval requirements
