import 'package:flutter/material.dart';
import 'package:muhasib/core/enums/quick_date_range.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

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
    // If the page provides an always-required filter (e.g. account selector),
    // show the filter panel by default so the control is immediately visible.
    if (widget.additionalFilters != null &&
        widget.additionalFilters!.isNotEmpty) {
      _showFilters = true;
    }
  }

  @override
  void didUpdateWidget(covariant ReportBasePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.additionalFilters != null &&
        widget.additionalFilters!.isNotEmpty &&
        (oldWidget.additionalFilters == null ||
            oldWidget.additionalFilters!.isEmpty)) {
      setState(() => _showFilters = true);
    }
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
    final range = QuickDateRange.tryFromCode(type);
    final now = DateTime.now();
    setState(() {
      _filter = switch (range) {
        QuickDateRange.today => _filter.copyWith(
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        ),
        QuickDateRange.week => () {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          return _filter.copyWith(
            startDate: DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day,
            ),
            endDate: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
          );
        }(),
        QuickDateRange.year => ReportFilter.currentYear(),
        _ => ReportFilter.currentMonth(),
      };
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Keep RTL context but allow inner scrollables to behave naturally.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: widget.color.withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    '${_formatDate(_filter.startDate)} - ${_formatDate(_filter.endDate)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
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
                      color: Colors.white.withValues(alpha: 0.2),
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

            // Search bar & Quick filters — required additionalFilters are ALWAYS visible
            if (widget.showSearch ||
                (_showFilters && widget.showDateFilter) ||
                (widget.additionalFilters != null &&
                    widget.additionalFilters!.isNotEmpty))
              Container(
                color: Theme.of(context).colorScheme.surface,
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
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
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
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
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
                            QuickFilterChipWidget(
                              label: 'اليوم',
                              color: widget.color,
                              onPressed: () => _applyQuickFilter('today'),
                            ),
                            const SizedBox(width: 8),
                            QuickFilterChipWidget(
                              label: 'الأسبوع',
                              color: widget.color,
                              onPressed: () => _applyQuickFilter('week'),
                            ),
                            const SizedBox(width: 8),
                            QuickFilterChipWidget(
                              label: 'الشهر الحالي',
                              color: widget.color,
                              onPressed: () => _applyQuickFilter('month'),
                            ),
                            const SizedBox(width: 8),
                            QuickFilterChipWidget(
                              label: 'العام الحالي',
                              color: widget.color,
                              onPressed: () => _applyQuickFilter('year'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Mandatory filters (e.g. account selector) — always visible
                    if (widget.additionalFilters != null &&
                        widget.additionalFilters!.isNotEmpty) ...[
                      if (_showFilters && widget.showDateFilter)
                        const Divider(height: 16)
                      else if (widget.showSearch)
                        const SizedBox(height: 8),
                      ...widget.additionalFilters!,
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
}

class QuickFilterChipWidget extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const QuickFilterChipWidget({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      onPressed: onPressed,
    );
  }
}
