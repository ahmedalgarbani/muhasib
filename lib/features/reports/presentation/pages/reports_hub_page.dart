import 'package:flutter/material.dart';
import 'package:muhasib/features/reports/data/reports_data.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
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
      category: ReportCategory.accounting,
    ),
    _TabInfo(
      title: 'المبيعات',
      icon: Icons.point_of_sale,
      category: ReportCategory.sales,
    ),
    _TabInfo(
      title: 'المشتريات',
      icon: Icons.shopping_cart,
      category: ReportCategory.purchases,
    ),
    _TabInfo(
      title: 'المخزون',
      icon: Icons.warehouse,
      category: ReportCategory.inventory,
    ),
    _TabInfo(
      title: 'العملاء',
      icon: Icons.people,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 34,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تقارير مطابقة',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'جرّب كلمة بحث مختلفة',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              label: const Text('مسح البحث'),
                            ),
                          ],
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
      );
  }
}

class _TabInfo {
  final String title;
  final IconData icon;
  final ReportCategory category;

  const _TabInfo({
    required this.title,
    required this.icon,
    required this.category,
  });
}
