import 'package:equatable/equatable.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {
  final String reportKey;
  const ReportsLoading({required this.reportKey});
  @override
  List<Object?> get props => [reportKey];
}

class ReportsLoaded extends ReportsState {
  final String reportKey;
  final List<Map<String, dynamic>> data;
  const ReportsLoaded({required this.reportKey, required this.data});
  @override
  List<Object?> get props => [reportKey, data];
}

class ReportsError extends ReportsState {
  final String reportKey;
  final String message;
  const ReportsError({required this.reportKey, required this.message});
  @override
  List<Object?> get props => [reportKey, message];
}
