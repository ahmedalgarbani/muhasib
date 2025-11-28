import '../../domain/entities/initial_setup_status.dart';

class InitialSetupStatusModel extends InitialSetupStatus {
  const InitialSetupStatusModel({required super.isComplete});

  factory InitialSetupStatusModel.fromJson(Map<String, dynamic> json) {
    return InitialSetupStatusModel(
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_complete': isComplete,
    };
  }

  InitialSetupStatus toEntity() {
    return InitialSetupStatus(isComplete: isComplete);
  }
}
