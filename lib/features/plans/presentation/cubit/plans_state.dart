import 'package:equatable/equatable.dart';
import 'package:muhasib/features/plans/domain/entities/license_entity.dart';
import 'package:muhasib/features/plans/domain/entities/plan_entity.dart';

abstract class PlansState extends Equatable {
  const PlansState();

  @override
  List<Object?> get props => [];
}

class PlansInitial extends PlansState {
  const PlansInitial();
}

class PlansLoading extends PlansState {
  const PlansLoading();
}

class PlansLoaded extends PlansState {
  final PlanEntity plan;
  final LicenseEntity? license;
  final bool expired;
  final bool trial;
  final int? daysRemaining;
  final String? deviceId;

  const PlansLoaded({
    required this.plan,
    this.license,
    this.expired = false,
    this.trial = false,
    this.daysRemaining,
    this.deviceId,
  });

  @override
  List<Object?> get props =>
      [plan, license, expired, trial, daysRemaining, deviceId];
}

class PlansError extends PlansState {
  final String message;

  const PlansError(this.message);

  @override
  List<Object?> get props => [message];
}
