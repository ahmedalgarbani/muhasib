# Account Widgets Documentation

## Overview
This folder contains reusable widgets for displaying account information in the Hasib accounting application.

## Widgets

### 1. `AccountColorHelper`
**Purpose:** Centralized color management for accounts based on type and master status.

**Usage:**
```dart
final colors = AccountColorHelper.getColors(account);
// Returns: (background: Color, border: Color, icon: Color)
```

**Color Scheme:**
- **Master Accounts:** Yellow/Amber (`#FEF3C7`, `#F59E0B`)
- **Type 0 (Assets):** Green (`#DCFCE7`, `#10B981`)
- **Type 1 (Liabilities):** Red (`#FEE2E2`, `#EF4444`)
- **Type 2 (Equity):** Indigo (`#E0E7FF`, `#6366F1`)
- **Type 3 (Revenue):** Green
- **Type 4 (Expenses):** Red
- **Default:** Grey

---

### 2. `AccountCardHeader`
**Purpose:** Displays account icon, name, code, badge, and optional menu.

**Props:**
- `account`: AccountEntity (required)
- `backgroundColor`: Color (required)
- `iconColor`: Color (required)
- `borderColor`: Color (required)
- `onEdit`: VoidCallback? (optional)
- `onDelete`: VoidCallback? (optional)

**Features:**
- Shows folder icon for master accounts, document icon for sub accounts
- Displays account name and code
- Badge showing "رئيسي" or "فرعي"
- Optional popup menu for edit/delete actions

---

### 3. `AccountBalanceRow`
**Purpose:** Displays formatted account balance with trend indicator.

**Props:**
- `balance`: double (required)
- `currency`: String (default: 'ريال')

**Features:**
- Trending up/down icon based on positive/negative balance
- Formatted numbers using Arabic locale
- Color-coded (green for positive, red for negative)

---

### 4. `AccountCardDivider`
**Purpose:** Consistent divider line for account cards.

**Props:**
- `color`: Color (required)

**Features:**
- 1px height divider with 30% opacity

---

### 5. `MainCardAccount`
**Purpose:** Card widget for master accounts with sub-accounts indicator.

**Props:**
- `account`: AccountEntity (required)
- `backgroundColor`: Color (required)
- `borderColor`: Color (required)
- `iconColor`: Color (required)
- `onTap`: VoidCallback? (optional)
- `onEdit`: VoidCallback? (optional)
- `onDelete`: VoidCallback? (optional)

**Features:**
- Uses `AccountCardHeader` for header section
- Uses `AccountBalanceRow` for balance display
- Shows "اضغط لعرض الحسابات الفرعية" for master accounts
- Rounded corners with shadow
- Tap to navigate to sub-accounts

---

### 6. `SubCardAccount`
**Purpose:** Card widget for sub/leaf accounts.

**Props:**
- `account`: AccountEntity (required)
- `backgroundColor`: Color (required)
- `borderColor`: Color (required)
- `iconColor`: Color (required)
- `onEdit`: VoidCallback? (optional)
- `onDelete`: VoidCallback? (optional)

**Features:**
- Uses `AccountCardHeader` for header section
- Uses `AccountBalanceRow` for balance display
- Tap to navigate to account transactions
- Simpler layout compared to master accounts

---

## Usage Example

```dart
// Get colors
final colors = AccountColorHelper.getColors(account);

// Display account card
account.isMaster
    ? MainCardAccount(
        account: account,
        onTap: () => navigateToSubAccounts(),
        backgroundColor: colors.background,
        borderColor: colors.border,
        iconColor: colors.icon,
        onEdit: () => editAccount(),
        onDelete: () => deleteAccount(),
      )
    : SubCardAccount(
        account: account,
        backgroundColor: colors.background,
        borderColor: colors.border,
        iconColor: colors.icon,
        onEdit: () => editAccount(),
        onDelete: () => deleteAccount(),
      );
```

## Benefits

✅ **DRY Principle:** No code duplication  
✅ **Consistency:** Same look and feel across the app  
✅ **Maintainability:** Easy to update colors and styles  
✅ **Reusability:** Use in multiple screens  
✅ **Testability:** Each widget can be tested independently  

## Files Structure

```
widgets/
├── account_color_helper.dart       # Color management
├── account_card_header.dart        # Header component
├── account_balance_row.dart        # Balance display
├── account_card_divider.dart       # Divider line
├── main_card_account.dart          # Master account card
├── sub_card_account.dart           # Sub account card
└── README.md                       # This file
```
