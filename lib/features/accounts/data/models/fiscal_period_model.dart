import '../../domain/entities/fiscal_period_entity.dart';

class FiscalPeriodModel extends FiscalPeriodEntity {
  const FiscalPeriodModel({
    super.id,
    required super.year,
    required super.period,
    required super.startDate,
    required super.endDate,
    super.status,
    super.isClosed,
    super.closedBy,
    super.closedAt,
    super.notes,
    super.creationTime,
    super.lastModificationTime,
  });

  factory FiscalPeriodModel.fromJson(Map<String, dynamic> json) {
    return FiscalPeriodModel(
      id: json['id'] as int?,
      year: json['year'] as int,
      period: json['period'] as int,
      startDate: DateTime.fromMillisecondsSinceEpoch((json['start_date'] as int) * 1000),
      endDate: DateTime.fromMillisecondsSinceEpoch((json['end_date'] as int) * 1000),
      status: json['status'] as int? ?? 0,
      isClosed: (json['is_closed'] as int? ?? 0) == 1,
      closedBy: json['closed_by'] as int?,
      closedAt: json['closed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['closed_at'] as int) * 1000)
          : null,
      notes: json['notes'] as String?,
      creationTime: json['creation_time'] as int?,
      lastModificationTime: json['last_modification_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      if (id != null) 'id': id,
      'year': year,
      'period': period,
      'start_date': startDate.millisecondsSinceEpoch ~/ 1000,
      'end_date': endDate.millisecondsSinceEpoch ~/ 1000,
      'status': status,
      'is_closed': isClosed ? 1 : 0,
      'closed_by': closedBy,
      if (closedAt != null) 'closed_at': closedAt!.millisecondsSinceEpoch ~/ 1000,
      'notes': notes,
      'creation_time': creationTime ?? now,
      'last_modification_time': lastModificationTime ?? now,
    };
  }

  factory FiscalPeriodModel.fromEntity(FiscalPeriodEntity entity) {
    return FiscalPeriodModel(
      id: entity.id,
      year: entity.year,
      period: entity.period,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
      isClosed: entity.isClosed,
      closedBy: entity.closedBy,
      closedAt: entity.closedAt,
      notes: entity.notes,
      creationTime: entity.creationTime,
      lastModificationTime: entity.lastModificationTime,
    );
  }

  FiscalPeriodEntity toEntity() {
    return FiscalPeriodEntity(
      id: id,
      year: year,
      period: period,
      startDate: startDate,
      endDate: endDate,
      status: status,
      isClosed: isClosed,
      closedBy: closedBy,
      closedAt: closedAt,
      notes: notes,
      creationTime: creationTime,
      lastModificationTime: lastModificationTime,
    );
  }
}
