import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';

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
        return const Color(0xFF2563EB); // Blue
      case InvoiceType.purchaseInvoice:
        return const Color(0xFF7C3AED); // Purple
      case InvoiceType.quotation:
        return const Color(0xFFF59E0B); // Orange
      case InvoiceType.salesReturn:
        return const Color(0xFFEF4444); // Red
      case InvoiceType.purchaseReturn:
        return const Color(0xFFDC2626); // Dark Red
      case InvoiceType.quickInvoice:
        return const Color(0xFF10B981); // Green
    }
  }

  /// Get background color (lighter tint)
  static Color getBackgroundColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.salesInvoice:
        return const Color(0xFFDBEAFE);
      case InvoiceType.purchaseInvoice:
        return const Color(0xFFF3E8FF);
      case InvoiceType.quotation:
        return const Color(0xFFFEF3C7);
      case InvoiceType.salesReturn:
        return const Color(0xFFFEE2E2);
      case InvoiceType.purchaseReturn:
        return const Color(0xFFFECDD3);
      case InvoiceType.quickInvoice:
        return const Color(0xFFD1FAE5);
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
        return const Color(0xFF6B7280); // Gray
      case InvoiceStatus.open:
        return const Color(0xFF3B82F6); // Blue
      case InvoiceStatus.approved:
        return const Color(0xFF10B981); // Green
      case InvoiceStatus.cancelled:
        return const Color(0xFFEF4444); // Red
      case InvoiceStatus.converted:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  /// Get background color
  static Color getBackgroundColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return const Color(0xFFF3F4F6);
      case InvoiceStatus.open:
        return const Color(0xFFDBEAFE);
      case InvoiceStatus.approved:
        return const Color(0xFFD1FAE5);
      case InvoiceStatus.cancelled:
        return const Color(0xFFFEE2E2);
      case InvoiceStatus.converted:
        return const Color(0xFFF3E8FF);
    }
  }

  /// Get text color
  static Color getTextColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return const Color(0xFF374151);
      case InvoiceStatus.open:
        return const Color(0xFF1E40AF);
      case InvoiceStatus.approved:
        return const Color(0xFF065F46);
      case InvoiceStatus.cancelled:
        return const Color(0xFF991B1B);
      case InvoiceStatus.converted:
        return const Color(0xFF6B21A8);
    }
  }
}

/// Status Badge Widget
class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  final bool showIcon;

  const InvoiceStatusBadge({
    Key? key,
    required this.status,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: InvoiceStatusUI.getBackgroundColor(status),
        borderRadius: BorderRadius.circular(12),
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
    Key? key,
    required this.type,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: InvoiceTypeUI.getBackgroundColor(type),
        borderRadius: BorderRadius.circular(12),
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
