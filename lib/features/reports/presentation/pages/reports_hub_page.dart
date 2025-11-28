import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/features/reports/data/reports_data.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';

class ReportsHubPage extends StatefulWidget {
  const ReportsHubPage({super.key});

  @override
  State<ReportsHubPage> createState() => _ReportsHubPageState();
}

class _ReportsHubPageState extends State<ReportsHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_TabInfo> _tabs = const [
    _TabInfo(
      title: 'المحاسبة',
      icon: Icons.account_balance,
      color: Color(0xFF1976D2),
      category: ReportCategory.accounting,
    ),
    _TabInfo(
      title: 'المبيعات',
      icon: Icons.point_of_sale,
      color: Color(0xFF388E3C),
      category: ReportCategory.sales,
    ),
    _TabInfo(
      title: 'المشتريات',
      icon: Icons.shopping_cart,
      color: Color(0xFF7B1FA2),
      category: ReportCategory.purchases,
    ),
    _TabInfo(
      title: 'المخزون',
      icon: Icons.warehouse,
      color: Color(0xFFFF5722),
      category: ReportCategory.inventory,
    ),
    _TabInfo(
      title: 'العملاء',
      icon: Icons.people,
      color: Color(0xFF00ACC1),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'التقارير',
          style: TextStyle(
            color: Color(0xFF4A90E2),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF4A90E2),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4A90E2),
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((tab) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 20),
                const SizedBox(width: 8),
                Text(tab.title),
              ],
            ),
          )).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في التقارير...',
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
                  borderRadius: BorderRadius.circular(12),
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
                return _buildReportsList(_getFilteredReports(tab.category), tab.color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<ReportItem> reports, Color accentColor) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
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
        return _buildReportCard(reports[index]);
      },
    );
  }

  Widget _buildReportCard(ReportItem report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push(report.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  report.icon,
                  color: report.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.titleAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.descriptionAr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: report.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: report.color,
                  size: 16,
                ),
              ),
            ],
          ),
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

