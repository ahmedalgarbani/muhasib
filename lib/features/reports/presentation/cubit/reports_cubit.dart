import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/reports/domain/usecases/get_report_data.dart';
import 'package:muhasib/features/reports/presentation/cubit/reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportData getReportData;

  ReportsCubit({required this.getReportData}) : super(ReportsInitial());

  Future<void> loadReport(GetReportDataParams params) async {
    emit(ReportsLoading(reportKey: params.reportKey));
    final result = await getReportData(params: params);
    result.fold(
      (failure) => emit(ReportsError(reportKey: params.reportKey, message: failure.message)),
      (data) => emit(ReportsLoaded(reportKey: params.reportKey, data: data)),
    );
  }

  Future<List<Map<String, dynamic>>> loadReportData(GetReportDataParams params) async {
    final result = await getReportData(params: params);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }
}
