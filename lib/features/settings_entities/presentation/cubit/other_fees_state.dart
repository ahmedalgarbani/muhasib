part of 'other_fees_cubit.dart';

abstract class OtherFeesState extends Equatable {
  const OtherFeesState();

  @override
  List<Object?> get props => [];
}

class OtherFeesInitial extends OtherFeesState {}

class OtherFeesLoading extends OtherFeesState {}

class OtherFeesLoaded extends OtherFeesState {
  final List<OtherFeeEntity> otherFees;

  const OtherFeesLoaded(this.otherFees);

  @override
  List<Object?> get props => [otherFees];
}

class OtherFeeCreated extends OtherFeesState {
  final int id;

  const OtherFeeCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class OtherFeeUpdated extends OtherFeesState {}

class OtherFeeDeleted extends OtherFeesState {}

class OtherFeesError extends OtherFeesState {
  final String message;

  const OtherFeesError(this.message);

  @override
  List<Object?> get props => [message];
}

