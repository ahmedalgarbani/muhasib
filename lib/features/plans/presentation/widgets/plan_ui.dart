import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';

import '../../domain/entities/plan_feature.dart';
import '../../domain/entities/plan_tier.dart';
import '../../domain/plans_catalog.dart';

extension PlanTierUi on PlanTier {
  Color get color {
    switch (this) {
      case PlanTier.free:
        return AppColors.slate500;
      case PlanTier.basic:
        return AppColors.info;
      case PlanTier.pro:
        return AppColors.primary;
      case PlanTier.enterprise:
        return AppColors.violet700;
      case PlanTier.trial:
        return AppColors.amber600;
    }
  }

  IconData get icon {
    switch (this) {
      case PlanTier.free:
        return Icons.storefront_outlined;
      case PlanTier.basic:
        return Icons.rocket_launch_outlined;
      case PlanTier.pro:
        return Icons.workspace_premium_outlined;
      case PlanTier.enterprise:
        return Icons.corporate_fare_outlined;
      case PlanTier.trial:
        return Icons.hourglass_top_outlined;
    }
  }
}

extension PlanFeatureUi on PlanFeature {
  IconData get icon {
    switch (this) {
      case PlanFeature.pointOfSale:
        return Icons.point_of_sale_outlined;
      case PlanFeature.salesInvoices:
        return Icons.receipt_long_outlined;
      case PlanFeature.salesReturns:
        return Icons.assignment_return_outlined;
      case PlanFeature.quotations:
        return Icons.request_quote_outlined;
      case PlanFeature.purchases:
        return Icons.shopping_cart_outlined;
      case PlanFeature.purchaseReturns:
        return Icons.keyboard_return_outlined;
      case PlanFeature.purchaseOrders:
        return Icons.playlist_add_check_outlined;
      case PlanFeature.products:
        return Icons.inventory_2_outlined;
      case PlanFeature.multiUnit:
        return Icons.straighten_outlined;
      case PlanFeature.customers:
        return Icons.people_outline;
      case PlanFeature.suppliers:
        return Icons.local_shipping_outlined;
      case PlanFeature.stockOperations:
        return Icons.swap_horiz_outlined;
      case PlanFeature.warehouses:
        return Icons.warehouse_outlined;
      case PlanFeature.accounting:
        return Icons.menu_book_outlined;
      case PlanFeature.multiCurrency:
        return Icons.currency_exchange_outlined;
      case PlanFeature.reportsBasic:
        return Icons.bar_chart_outlined;
      case PlanFeature.reportsAdvanced:
        return Icons.insights_outlined;
      case PlanFeature.barcodeScanning:
        return Icons.qr_code_scanner_outlined;
      case PlanFeature.backup:
        return Icons.backup_outlined;
      case PlanFeature.users:
        return Icons.group_outlined;
      case PlanFeature.prioritySupport:
        return Icons.support_agent_outlined;
    }
  }

  /// Cheapest purchasable plan that unlocks this feature.
  PlanTier? get minimumTier {
    for (final plan in PlansCatalog.purchasablePlans) {
      if (plan.hasFeature(this)) return plan.tier;
    }
    return null;
  }
}
