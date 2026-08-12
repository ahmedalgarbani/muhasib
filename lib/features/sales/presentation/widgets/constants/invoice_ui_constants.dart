import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// UI Constants and helpers for Invoice Types
class InvoiceTypeUI {
  /// Get icon for invoice type
  static IconData getIcon(InvoiceType type) {
    switch (type) {
      case InvoiceType.salesInvoice:
        return Icons.receipt_long;
      case InvoiceType.purchaseInvoice:
        return Icons.shopping_cart;
      case InvoiceType.quotation:
        return Icons.request_quote;
      case InvoiceType.salesReturn:
        return Icons.assignment_return;
      case InvoiceType.purchaseReturn:
        return Icons.keyboard_return;
      case InvoiceType.quickInvoice:
        return Icons.flash_on;
    }
  }

  /// Get color for invoice type
  static Color getColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.salesInvoice:
        return AppColors.primary; // Blue
      case InvoiceType.purchaseInvoice:
        return AppColors.violet700; // Purple
      case InvoiceType.quotation:
        return AppColors.warning; // Orange
      case InvoiceType.salesReturn:
        return AppColors.error; // Red
      case InvoiceType.purchaseReturn:
        return AppColors.red600; // Dark Red
      case InvoiceType.quickInvoice:
        return AppColors.success; // Green
    }
  }

  /// Get background color (lighter tint)
  static Color getBackgroundColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.salesInvoice:
        return AppColors.blue100;
      case InvoiceType.purchaseInvoice:
        return AppColors.purple100;
      case InvoiceType.quotation:
        return AppColors.amber100;
      case InvoiceType.salesReturn:
        return AppColors.red100;
      case InvoiceType.purchaseReturn:
        return AppColors.red200;
      case InvoiceType.quickInvoice:
        return AppColors.emerald100;
    }
  }
}

/// UI Constants and helpers for Invoice Status
class InvoiceStatusUI {
  /// Get icon for invoice status
  static IconData getIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit_note;
      case InvoiceStatus.open:
        return Icons.description;
      case InvoiceStatus.approved:
        return Icons.check_circle;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.converted:
        return Icons.transform;
    }
  }

  /// Get color for invoice status
  static Color getColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return AppColors.gray500; // Gray
      case InvoiceStatus.open:
        return AppColors.info; // Blue
      case InvoiceStatus.approved:
        return AppColors.success; // Green
      case InvoiceStatus.cancelled:
        return AppColors.error; // Red
      case InvoiceStatus.converted:
        return AppColors.violet500; // Purple
    }
  }

  /// Get background color
  static Color getBackgroundColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return AppColors.gray100;
      case InvoiceStatus.open:
        return AppColors.blue100;
      case InvoiceStatus.approved:
        return AppColors.emerald100;
      case InvoiceStatus.cancelled:
        return AppColors.red100;
      case InvoiceStatus.converted:
        return AppColors.purple100;
    }
  }

  /// Get text color
  static Color getTextColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return AppColors.gray700;
      case InvoiceStatus.open:
        return AppColors.blue800;
      case InvoiceStatus.approved:
        return AppColors.emerald800;
      case InvoiceStatus.cancelled:
        return AppColors.red800;
      case InvoiceStatus.converted:
        return AppColors.purple800;
    }
  }
}

/// Status Badge Widget
class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool showIcon;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: InvoiceStatusUI.getBackgroundColor(status),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: InvoiceStatusUI.getColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              InvoiceStatusUI.getIcon(status),
              size: 16,
              color: InvoiceStatusUI.getTextColor(status),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: InvoiceStatusUI.getTextColor(status),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type Badge Widget
class InvoiceTypeBadge extends StatelessWidget {
  final InvoiceType type;
  final bool showIcon;

  const InvoiceTypeBadge({
    super.key,
    required this.type,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: InvoiceTypeUI.getBackgroundColor(type),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: InvoiceTypeUI.getColor(type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              InvoiceTypeUI.getIcon(type),
              size: 16,
              color: InvoiceTypeUI.getColor(type),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: InvoiceTypeUI.getColor(type),
            ),
          ),
        ],
      ),
    );
  }
}
