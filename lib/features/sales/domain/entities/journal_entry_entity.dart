import 'package:equatable/equatable.dart';
import 'journal_line_entity.dart';

class JournalEntryEntity extends Equatable {
  final int? id;
  final int date;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final List<JournalLineEntity> lines;
  final bool isAutomatic;
  final String status;
  final int? createdBy;
  final int? creationTime;
  final int? lastModificationTime;

  const JournalEntryEntity({
    this.id,
    required this.date,
    required this.description,
    this.referenceType,
    this.referenceId,
    required this.lines,
    this.isAutomatic = false,
    this.status = 'draft',
    this.createdBy,
    this.creationTime,
    this.lastModificationTime,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        description,
        referenceType,
        referenceId,
        lines,
        isAutomatic,
        status,
        createdBy,
        creationTime,
        lastModificationTime,
      ];

  JournalEntryEntity copyWith({
    int? id,
    int? date,
    String? description,
    String? referenceType,
    int? referenceId,
    List<JournalLineEntity>? lines,
    bool? isAutomatic,
    String? status,
    int? createdBy,
    int? creationTime,
    int? lastModificationTime,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      lines: lines ?? this.lines,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      creationTime: creationTime ?? this.creationTime,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
    );
  }
}
