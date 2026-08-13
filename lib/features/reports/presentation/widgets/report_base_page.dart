import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class ReportBasePage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(ReportFilter filter) reportBuilder;
  final bool showDateFilter;
  final bool showSearch;
  final String searchHint;
  final List<Widget>? additionalFilters;
  final List<Widget>? actions;
  final VoidCallback? onPrint;
  final VoidCallback? onExportExcel;

  const ReportBasePage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.reportBuilder,
    this.showDateFilter = true,
    this.showSearch = true,
    this.searchHint = 'بحث بالاسم، الكود، أو التفاصيل...',
    this.additionalFilters,
    this.actions,
    this.onPrint,
    this.onExportExcel,
  });

  @override
  State<ReportBasePage> createState() => _ReportBasePageState();
}

class _ReportBasePageState extends State<ReportBasePage> {
  late ReportFilter _filter;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = ReportFilter.currentMonth();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          endDate: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
            999,
          ),
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
            startDate: DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day,
            ),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: widget.title,
          actions: [
            if (widget.showDateFilter)
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: 'الفلاتر',
              ),
            if (widget.onPrint != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: widget.onPrint,
                tooltip: 'تصدير PDF',
              ),
            if (widget.onExportExcel != null)
              IconButton(
                icon: const Icon(Icons.table_view),
                onPressed: widget.onExportExcel,
                tooltip: 'تصدير Excel',
              ),
            ...?widget.actions,
          ],
        ),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.showDateFilter &&
                            _filter.startDate != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                color: Colors.white.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatDate(_filter.startDate)} - ${_formatDate(_filter.endDate)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.showDateFilter)
                    Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: IconButton(
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                        ),
                        onPressed: _selectDateRange,
                        tooltip: 'تغيير الفترة',
                      ),
                    ),
                ],
              ),
            ),

            // Search bar & Quick filters
            if (widget.showSearch || (_showFilters && widget.showDateFilter))
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showSearch)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextInputField(
                          controller: _searchController,
                          hint: widget.searchHint,
                          decoration: InputDecoration(
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _filter = _filter.copyWith(
                                          searchQuery: '',
                                        );
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.gray50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _filter = _filter.copyWith(
                                searchQuery: val.trim(),
                              );
                            });
                          },
                        ),
                      ),
                    if (_showFilters && widget.showDateFilter) ...[
                      const Text(
                        'الفترة الزمنية السريعة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickFilterChip('اليوم', 'today'),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('الأسبوع', 'week'),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('الشهر الحالي', 'month'),
                            const SizedBox(width: 8),
                            _buildQuickFilterChip('العام الحالي', 'year'),
                          ],
                        ),
                      ),
                      if (widget.additionalFilters != null) ...[
                        const Divider(height: 16),
                        ...widget.additionalFilters!,
                      ],
                    ],
                  ],
                ),
              ),

            // Report content
            Expanded(child: widget.reportBuilder(_filter)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, String type) {
    return ActionChip(
      label: Text(label),
      backgroundColor: widget.color.withOpacity(0.05),
      labelStyle: TextStyle(
        color: widget.color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(color: widget.color.withOpacity(0.2)),
      onPressed: () => _applyQuickFilter(type),
    );
  }
}
