import '../../domain/entities/journal_entry_entity.dart';
import 'journal_entry_line_model.dart';

class JournalEntryModel extends JournalEntryEntity {
  const JournalEntryModel({
    super.id,
    required super.number,
    required super.entryDate,
    super.description,
    super.referenceNumber,
    super.referenceType,
    super.referenceId,
    super.notes,
    super.status,
    super.isPosted,
    required super.totalDebit,
    required super.totalCredit,
    required super.difference,
    super.lines,
  });

  factory JournalEntryModel.fromJson(
    Map<String, dynamic> json, {
    List<JournalEntryLineModel> lines = const [],
  }) {
    final rawEntryDate = (json['entry_date'] as int?) ?? 0;
    // Some old code stored milliseconds; normalize to milliseconds for DateTime.
    final entryDateMs = rawEntryDate > 1000000000000 ? rawEntryDate : rawEntryDate * 1000;
    return JournalEntryModel(
      id: json['id'] as int?,
      number: (json['number'] as String?) ?? '',
      entryDate: DateTime.fromMillisecondsSinceEpoch(entryDateMs),
      description: json['description'] as String?,
      referenceNumber: json['reference_number'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as int?,
      notes: json['notes'] as String?,
      status: json['status'] as int? ?? 0,
      isPosted: (json['is_posted'] as int? ?? 0) == 1,
      totalDebit: (json['total_debit'] as num).toDouble(),
      totalCredit: (json['total_credit'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      lines: lines,
    );
  }

  factory JournalEntryModel.fromEntity(JournalEntryEntity entity) {
    final lineModels = entity.lines
        .map((line) => JournalEntryLineModel.fromEntity(line))
        .toList();

    return JournalEntryModel(
      id: entity.id,
      number: entity.number,
      entryDate: entity.entryDate,
      description: entity.description,
      referenceNumber: entity.referenceNumber,
      referenceType: entity.referenceType,
      referenceId: entity.referenceId,
      notes: entity.notes,
      status: entity.status,
      isPosted: entity.isPosted,
      totalDebit: entity.totalDebit,
      totalCredit: entity.totalCredit,
      difference: entity.difference,
      lines: lineModels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      // Store seconds to match reports and other modules.
      'entry_date': entryDate.millisecondsSinceEpoch ~/ 1000,
      'description': description,
      'reference_number': referenceNumber,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'status': status,
      'is_posted': isPosted ? 1 : 0,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'difference': difference,
    };
  }

  JournalEntryModel copyWithLines(List<JournalEntryLineEntity> lines) {
    return JournalEntryModel(
      id: id,
      number: number,
      entryDate: entryDate,
      description: description,
      referenceNumber: referenceNumber,
      referenceType: referenceType,
      referenceId: referenceId,
      notes: notes,
      status: status,
      isPosted: isPosted,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      difference: difference,
      lines: lines,
    );
  }
}
