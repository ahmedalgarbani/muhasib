import 'package:equatable/equatable.dart';
import 'package:muhasib/features/reports/domain/entities/transaction_entity.dart';

abstract class TransactionsReportState extends Equatable {
  const TransactionsReportState();

  @override
  List<Object?> get props => [];
}

class TransactionsReportInitial extends TransactionsReportState {}

class TransactionsReportLoading extends TransactionsReportState {}

class TransactionsReportLoaded extends TransactionsReportState {
  final List<TransactionEntity> transactions;
  final Map<String, dynamic> summary;
  final String selectedType;
  final String sortBy;
  final bool isAscending;

  const TransactionsReportLoaded({
    required this.transactions,
    required this.summary,
    this.selectedType = 'all',
    this.sortBy = 'date',
    this.isAscending = false,
  });

  @override
  List<Object?> get props => [
        transactions,
        summary,
        selectedType,
        sortBy,
        isAscending,
      ];

  TransactionsReportLoaded copyWith({
    List<TransactionEntity>? transactions,
    Map<String, dynamic>? summary,
    String? selectedType,
    String? sortBy,
    bool? isAscending,
  }) {
    return TransactionsReportLoaded(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      selectedType: selectedType ?? this.selectedType,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}

class TransactionsReportError extends TransactionsReportState {
  final String message;

  const TransactionsReportError({required this.message});

  @override
  List<Object?> get props => [message];
}

class TransactionsReportSearching extends TransactionsReportState {
  final List<TransactionEntity> previousTransactions;

  const TransactionsReportSearching({required this.previousTransactions});

  @override
  List<Object?> get props => [previousTransactions];
}
