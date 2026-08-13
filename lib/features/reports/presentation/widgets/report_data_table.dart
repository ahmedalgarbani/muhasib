import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class ReportTableColumn {
  final String title;
  final int flex;
  final TextAlign alignment;

  const ReportTableColumn({
    required this.title,
    this.flex = 1,
    this.alignment = TextAlign.start,
  });
}

class ReportDataTable<T> extends StatelessWidget {
  final List<ReportTableColumn> columns;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) rowBuilder;
  final Widget? footerRow;
  final String emptyMessage;

  const ReportDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.footerRow,
    this.emptyMessage = 'لا توجد بيانات متاحة للفترة أو البحث المحدد',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.gray100,
              child: Row(
                children: columns.map((col) {
                  return Expanded(
                    flex: col.flex,
                    child: Text(
                      col.title,
                      textAlign: col.alignment,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),

            // Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.gray100),
              itemBuilder: (context, index) {
                final isEven = index % 2 == 0;
                return Container(
                  color: isEven
                      ? Colors.white
                      : Colors.grey[50]?.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: rowBuilder(context, items[index], index),
                );
              },
            ),

            // Footer
            if (footerRow != null) ...[
              const Divider(height: 1, color: AppColors.gray300),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: AppColors.gray50,
                child: footerRow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
