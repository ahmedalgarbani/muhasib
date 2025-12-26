import 'package:muhasib/features/reports/domain/entities/sales_summary_entity.dart';

abstract class SalesSummaryState {}

class SalesSummaryInitial extends SalesSummaryState {}

class SalesSummaryLoading extends SalesSummaryState {}

class SalesSummaryLoaded extends SalesSummaryState {
  final SalesSummaryEntity summary;

  SalesSummaryLoaded({required this.summary});
}

class SalesSummaryError extends SalesSummaryState {
  final String message;

  SalesSummaryError({required this.message});
}
