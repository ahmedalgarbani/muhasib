import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

const int _millisecondsThreshold = 1000000000000;

int reportTimestampSeconds(DateTime date) =>
    date.millisecondsSinceEpoch ~/ 1000;

String normalizedReportTimestampSql(String column) =>
    '(CASE WHEN $column > $_millisecondsThreshold '
    'THEN CAST($column / 1000 AS INTEGER) ELSE $column END)';

List<Object?> reportDateRangeArgs(ReportFilter filter) {
  if (filter.startDate == null || filter.endDate == null) return const [];
  return [
    reportTimestampSeconds(filter.startDate!),
    reportTimestampSeconds(filter.endDate!),
  ];
}

DateTime dateTimeFromReportTimestamp(num timestamp) {
  final value = timestamp.toInt();
  return DateTime.fromMillisecondsSinceEpoch(
    value > _millisecondsThreshold ? value : value * 1000,
  );
}
