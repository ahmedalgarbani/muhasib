part of 'main_cubit.dart';

class RecentTransactionEntity extends Equatable {
  final String title;
  final String amount;
  final String date;
  final bool isIncome;
  final IconData icon;
  final DateTime timestamp;

  const RecentTransactionEntity({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.icon,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [title, amount, date, isIncome, icon, timestamp];
}

abstract class MainState extends Equatable {
  const MainState();

  @override
  List<Object?> get props => [];
}

class MainInitial extends MainState {}

class MainLoading extends MainState {}

class MainDashboardLoaded extends MainState {
  final int customersCount;
  final int suppliersCount;
  final List<RecentTransactionEntity> recentTransactions;

  const MainDashboardLoaded({
    required this.customersCount,
    required this.suppliersCount,
    required this.recentTransactions,
  });

  @override
  List<Object?> get props => [customersCount, suppliersCount, recentTransactions];
}

class MainError extends MainState {
  final String message;

  const MainError(this.message);

  @override
  List<Object?> get props => [message];
}
