import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/safe_pop.dart';
import 'package:muhasib/features/reports/data/reports_data.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/reports/presentation/widgets/report_card_widget.dart';

class ReportsHubPage extends StatefulWidget {
  const ReportsHubPage({super.key});

  @override
  State<ReportsHubPage> createState() => _ReportsHubPageState();
}

class _ReportsHubPageState extends State<ReportsHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      title: 'المحاسبة',
      icon: Icons.account_balance,
      color: AppColors.materialBlue700,
      category: ReportCategory.accounting,
    ),
    _TabInfo(
      title: 'المبيعات',
      icon: Icons.point_of_sale,
      color: AppColors.materialGreen700,
      category: ReportCategory.sales,
    ),
    _TabInfo(
      title: 'المشتريات',
      icon: Icons.shopping_cart,
      color: AppColors.materialPurple700,
      category: ReportCategory.purchases,
    ),
    _TabInfo(
      title: 'المخزون',
      icon: Icons.warehouse,
      color: AppColors.materialDeepOrange500,
      category: ReportCategory.inventory,
    ),
    _TabInfo(
      title: 'العملاء',
      icon: Icons.people,
      color: AppColors.materialCyan700,
      category: ReportCategory.customers,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ReportItem> _getFilteredReports(ReportCategory category) {
    final reports = ReportsData.getReportsByCategory(category);
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      return report.titleAr.contains(_searchQuery) ||
          report.titleEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.descriptionAr.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: theme.dividerColor, width: 1),
              ),
              child: InkWell(
                onTap: () => context.safePop(),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'مركز التقارير',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl28),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                tabs: _tabs
                    .map(
                      (tab) => Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl28),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab.icon, size: 16),
                              const SizedBox(width: 6),
                              Text(tab.title),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextInputField(
                controller: _searchController,
                hint: 'بحث في التقارير...',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final reports = _getFilteredReports(tab.category);
                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تقارير مطابقة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return ReportCardWidget(report: reports[index]);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String title;
  final IconData icon;
  final Color color;
  final ReportCategory category;

  const _TabInfo({
    required this.title,
    required this.icon,
    required this.color,
    required this.category,
  });
}
