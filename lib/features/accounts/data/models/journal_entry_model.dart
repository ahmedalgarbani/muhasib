import '../../domain/entities/journal_entry_entity.dart';
import 'journal_entry_line_model.dart';

class JournalEntryModel extends JournalEntryEntity {
  const JournalEntryModel({
    int? id,
    required String number,
    required DateTime entryDate,
    String? description,
    String? referenceNumber,
    String? notes,
    int status = 0,
    bool isPosted = false,
    required double totalDebit,
    required double totalCredit,
    required double difference,
    List<JournalEntryLineEntity> lines = const [],
  }) : super(
          id: id,
          number: number,
          entryDate: entryDate,
          description: description,
          referenceNumber: referenceNumber,
          notes: notes,
          status: status,
          isPosted: isPosted,
          totalDebit: totalDebit,
          totalCredit: totalCredit,
          difference: difference,
          lines: lines,
        );

  factory JournalEntryModel.fromJson(
    Map<String, dynamic> json, {
    List<JournalEntryLineModel> lines = const [],
  }) {
    return JournalEntryModel(
      id: json['id'] as int?,
      number: json['number'] as String,
      entryDate: DateTime.fromMillisecondsSinceEpoch(json['entry_date'] as int),
      description: json['description'] as String?,
      referenceNumber: json['reference_number'] as String?,
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
      'entry_date': entryDate.millisecondsSinceEpoch,
      'description': description,
      'reference_number': referenceNumber,
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
