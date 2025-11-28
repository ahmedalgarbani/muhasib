import 'package:flutter/material.dart';

enum ReportCategory {
  accounting,
  sales,
  purchases,
  inventory,
  customers,
}

class ReportItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final IconData icon;
  final Color color;
  final String route;
  final ReportCategory category;
  final bool requiresDateRange;
  final bool requiresAccount;

  const ReportItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.icon,
    required this.color,
    required this.route,
    required this.category,
    this.requiresDateRange = true,
    this.requiresAccount = false,
  });
}

