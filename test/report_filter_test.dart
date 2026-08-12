import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/reports/domain/entities/report_filter.dart';

void main() {
  test('default report periods include the complete final day', () {
    final month = ReportFilter.currentMonth();
    final year = ReportFilter.currentYear();

    expect(month.endDate!.hour, 23);
    expect(month.endDate!.minute, 59);
    expect(month.endDate!.second, 59);
    expect(year.endDate!.month, 12);
    expect(year.endDate!.day, 31);
    expect(year.endDate!.hour, 23);
  });
}