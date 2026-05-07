import 'package:equatable/equatable.dart';

/// Fiscal Period Entity
/// Represents a fiscal period (month or year) that can be opened or closed
class FiscalPeriodEntity extends Equatable {
  final int? id;
  final int year;
  final int period;  // 0 = full year, 1-12 = months
  final DateTime startDate;
  final DateTime endDate;
  final int status;  // 0 = open, 1 = closed, 2 = locked
  final bool isClosed;
  final int? closedBy;
  final DateTime? closedAt;
  final String? notes;
  final int? creationTime;
  final int? lastModificationTime;

  const FiscalPeriodEntity({
    this.id,
    required this.year,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.status = 0,
    this.isClosed = false,
    this.closedBy,
    this.closedAt,
    this.notes,
    this.creationTime,
    this.lastModificationTime,
  });

  bool get isOpen => !isClosed && status == 0;
  bool get isLocked => status == 2;

  @override
  List<Object?> get props => [
        id,
        year,
        period,
        startDate,
        endDate,
        status,
        isClosed,
        closedBy,
        closedAt,
        notes,
      ];
}
