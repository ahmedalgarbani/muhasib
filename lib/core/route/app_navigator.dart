import 'package:flutter/material.dart';
import 'package:muhasib/core/models/nav_item.dart';
import 'package:muhasib/core/route/route_names.dart';

class AppNavigator {
  static const List<NavItem> items = [
    // ======= Header Section =======
    NavItem(
      title: 'الصفحه الرئيسية',
      icon: Icons.home,
      route: AppRoutes.home,
      position: DrawerSection.header,
    ),

    // ======= الحسابات =======
    NavItem(
      title: 'الحسابات',
      icon: Icons.account_balance,
      route: AppRoutes.accounts,
      children: [
        NavItem(
          title: 'دليل الحسابات',
          icon: Icons.list_alt,
          route: AppRoutes.accountsGuide,
        ),
        NavItem(
          title: 'ربط الحسابات',
          icon: Icons.link,
          route: AppRoutes.accountsLink,
        ),
        NavItem(
          title: 'القيود اليومية',
          icon: Icons.receipt_long,
          route: AppRoutes.accountsJournal,
        ),
        NavItem(
          title: 'السندات',
          icon: Icons.description_outlined,
          route: AppRoutes.accountsVouchers,
        ),
        NavItem(
          title: 'الأرصدة الافتتاحية',
          icon: Icons.layers,
          route: AppRoutes.accountsOpeningBalance,
        ),
        NavItem(
          title: 'سقف الحسابات',
          icon: Icons.trending_up,
          route: AppRoutes.accountsLimits,
        ),
        // NavItem(
        //   title: 'الإغلاق السنوي',
        //   icon: Icons.lock_outline,
        //   route: AppRoutes.accountsAnnualClose,
        // ),
      ],
    ),

    // ======= العملات =======
    NavItem(
      title: 'العملات',
      icon: Icons.currency_exchange,
      route: AppRoutes.currencies,
      children: [
        NavItem(
          title: 'العملات',
          icon: Icons.attach_money,
          route: AppRoutes.currenciesManage,
        ),
        NavItem(
          title: 'صرف عملات',
          icon: Icons.sync_alt,
          route: AppRoutes.currenciesExchange,
        ),
      ],
    ),

    // ======= المبيعات =======
    NavItem(
      title: 'المبيعات',
      icon: Icons.shopping_cart_outlined,
      route: AppRoutes.sales,
      children: [
        NavItem(
          title: 'إضافة فاتورة',
          icon: Icons.add_circle_outline,
          route: AppRoutes.salesAddInvoice,
        ),
        NavItem(
          title: 'قائمة المبيعات',
          icon: Icons.list,
          route: AppRoutes.salesList,
        ),
        NavItem(
          title: 'عروض الأسعار',
          icon: Icons.handshake_outlined,
          route: AppRoutes.salesQuotes,
        ),
        NavItem(
          title: 'مردود المبيعات',
          icon: Icons.shopping_cart_checkout,
          route: AppRoutes.salesReturns,
        ),
      ],
    ),

    // ======= المشتريات =======
    NavItem(
      title: 'المشتريات',
      icon: Icons.shopping_bag_outlined,
      route: AppRoutes.purchases,
      children: [
        NavItem(
          title: 'إضافة فاتورة',
          icon: Icons.add_circle_outline,
          route: AppRoutes.purchasesAddInvoice,
        ),
        NavItem(
          title: 'قائمة المشتريات',
          icon: Icons.list,
          route: AppRoutes.purchasesList,
        ),
        NavItem(
          title: 'طلبات الشراء',
          icon: Icons.receipt_long,
          route: AppRoutes.purchasesOrders,
        ),
        NavItem(
          title: 'مردود المشتريات',
          icon: Icons.reply,
          route: AppRoutes.purchasesReturns,
        ),
      ],
    ),

    // ======= الأصناف =======
    NavItem(
      title: 'الأصناف',
      icon: Icons.inventory_2_outlined,
      route: AppRoutes.items,
      children: [
        NavItem(
          title: 'مجموعات الأصناف',
          icon: Icons.category,
          route: AppRoutes.itemsGroups,
        ),
        NavItem(
          title: 'وحدات القياس',
          icon: Icons.straighten,
          route: AppRoutes.itemsUnits,
        ),
        NavItem(
          title: 'الأصناف',
          icon: Icons.inventory,
          route: AppRoutes.itemsManage,
        ),
        NavItem(
          title: 'الوحدات الفرعية',
          icon: Icons.widgets,
          route: AppRoutes.itemsSubUnits,
        ),
        NavItem(
          title: 'التسعيرات',
          icon: Icons.local_offer,
          route: AppRoutes.itemsPricing,
        ),
        NavItem(
          title: 'حركة الأصناف',
          icon: Icons.compare_arrows,
          route: AppRoutes.itemsMovements,
        ),
      ],
    ),

    // ======= المخازن =======
    NavItem(
      title: 'المخازن',
      icon: Icons.store_mall_directory_outlined,
      route: AppRoutes.warehouses,
      children: [
        NavItem(
          title: 'المخازن',
          icon: Icons.store,
          route: AppRoutes.warehousesList,
        ),
        NavItem(
          title: 'الجرد المخزني',
          icon: Icons.inventory,
          route: AppRoutes.warehousesInventory,
        ),
        NavItem(
          title: 'التسوية المخزنية',
          icon: Icons.balance,
          route: AppRoutes.warehousesAdjustment,
        ),
        NavItem(
          title: 'التحويل المخزني',
          icon: Icons.swap_horiz,
          route: AppRoutes.warehousesTransfer,
        ),
      ],
    ),

    // ======= التهيئات =======
    NavItem(
      title: 'التهيئات',
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
      children: [
        // NavItem(
        //   title: 'التصنيفات',
        //   icon: Icons.account_tree,
        //   route: AppRoutes.settingsCategories,
        // ),
        NavItem(
          title: 'البنوك',
          icon: Icons.account_balance_wallet,
          route: AppRoutes.settingsBanks,
        ),
        NavItem(
          title: 'الصناديق',
          icon: Icons.savings_outlined,
          route: AppRoutes.settingsCashboxes,
        ),
        NavItem(
          title: 'الرسوم الأخرى',
          icon: Icons.payments_outlined,
          route: AppRoutes.settingsOtherFees,
        ),
        NavItem(
          title: 'المناطق',
          icon: Icons.location_city,
          route: AppRoutes.settingsRegions,
        ),
      ],
    ),

    // ======= الملفات الشخصية =======
    NavItem(
      title: 'الملفات الشخصية',
      icon: Icons.people_alt_outlined,
      route: AppRoutes.profiles,
      children: [
        NavItem(
          title: 'العملاء',
          icon: Icons.person_outline,
          route: AppRoutes.customersProfile,
        ),
        NavItem(
          title: 'الموردين',
          icon: Icons.store_outlined,
          route: AppRoutes.suppliersProfile,
        ),
      ],
    ),

    // ======= التقارير =======
    NavItem(
      title: 'التقارير',
      icon: Icons.bar_chart_outlined,
      route: AppRoutes.reports,
      children: [
        NavItem(
          title: 'الحركة المالية',
          icon: Icons.swap_vert,
          route: AppRoutes.reportsTransactions,
        ),
        NavItem(
          title: 'كشف حساب',
          icon: Icons.article_outlined,
          route: AppRoutes.reportsAccountStatement,
        ),
        NavItem(
          title: 'المزيد من التقارير',
          icon: Icons.more_horiz,
          route: AppRoutes.reportsMore,
        ),
      ],
    ),

    // ======= عن التطبيق =======
    NavItem(
      title: 'عن التطبيق',
      icon: Icons.info_outline,
      route: AppRoutes.about,
      position: DrawerSection.bottom,
      hasArrow: false,
      children: [
        NavItem(
          title: 'شرح عن التطبيق في يوتيوب',
          icon: Icons.ondemand_video,
          route: AppRoutes.aboutYoutube,
        ),
        NavItem(
          title: 'أخبر صديق',
          icon: Icons.share,
          route: AppRoutes.aboutShare,
        ),
        NavItem(
          title: 'قيّمنا',
          icon: Icons.star_border,
          route: AppRoutes.aboutRate,
        ),
        NavItem(
          title: 'المساعدة',
          icon: Icons.headset_mic,
          route: AppRoutes.aboutHelp,
        ),
        NavItem(
          title: 'سياسة الخصوصية',
          icon: Icons.privacy_tip_outlined,
          route: AppRoutes.aboutPrivacy,
        ),
        NavItem(
          title: 'شروط الخدمة',
          icon: Icons.rule_folder,
          route: AppRoutes.aboutTerms,
        ),
      ],
    ),
  ];

  static List<NavItem> bySection(DrawerSection section) =>
      items.where((i) => i.position == section).toList();
}
