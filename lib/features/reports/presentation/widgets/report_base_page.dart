import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

class ReportBasePage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(ReportFilter filter) reportBuilder;
  final bool showDateFilter;
  final List<Widget>? additionalFilters;
  final List<Widget>? actions;

  const ReportBasePage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.reportBuilder,
    this.showDateFilter = true,
    this.additionalFilters,
    this.actions,
  });

  @override
  State<ReportBasePage> createState() => _ReportBasePageState();
}

class _ReportBasePageState extends State<ReportBasePage> {
  late ReportFilter _filter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _filter = ReportFilter.currentMonth();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _filter.startDate != null && _filter.endDate != null
          ? DateTimeRange(start: _filter.startDate!, end: _filter.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.color,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }

  void _applyQuickFilter(String type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case 'today':
          _filter = _filter.copyWith(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
          break;
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _filter = _filter.copyWith(
            startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            endDate: now,
          );
          break;
        case 'month':
          _filter = ReportFilter.currentMonth();
          break;
        case 'year':
          _filter = ReportFilter.currentYear();
          break;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: widget.title,
        actions: [
          if (widget.showDateFilter)
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'الفلاتر',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري تحضير الطباعة...')),
              );
            },
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري تحضير المشاركة...')),
              );
            },
            tooltip: 'مشاركة',
          ),
          ...?widget.actions,
        ],
      ),
      body: Column(
        children: [
          // Header with icon and date range
          Container(
            color: widget.color,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.showDateFilter && _filter.startDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'من ${_formatDate(_filter.startDate)} إلى ${_formatDate(_filter.endDate)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.showDateFilter)
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    onPressed: _selectDateRange,
                  ),
              ],
            ),
          ),

          // Quick filters
          if (_showFilters && widget.showDateFilter)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'فلترة سريعة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickFilterChip('اليوم', 'today'),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('هذا الأسبوع', 'week'),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('هذا الشهر', 'month'),
                        const SizedBox(width: 8),
                        _buildQuickFilterChip('هذا العام', 'year'),
                      ],
                    ),
                  ),
                  if (widget.additionalFilters != null) ...[
                    const SizedBox(height: 12),
                    ...widget.additionalFilters!,
                  ],
                ],
              ),
            ),

          // Report content
          Expanded(
            child: widget.reportBuilder(_filter),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, String type) {
    return ActionChip(
      label: Text(label),
      backgroundColor: widget.color.withOpacity(0.1),
      labelStyle: TextStyle(color: widget.color),
      onPressed: () => _applyQuickFilter(type),
    );
  }
}

