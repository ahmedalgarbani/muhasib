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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutral100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.safePop(),
          ),
          title: const Text(
            'التقارير',
            style: TextStyle(
              color: AppColors.customBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.customBlue,
            indicatorWeight: 3,
            labelColor: AppColors.customBlue,
            unselectedLabelColor: Colors.grey,
            tabs: _tabs
                .map(
                  (tab) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(tab.title),
                      ],
                    ),
                  ),
                )
                .toList(),
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
                  fillColor: Colors.white,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
