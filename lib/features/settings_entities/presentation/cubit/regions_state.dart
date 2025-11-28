part of 'regions_cubit.dart';

abstract class RegionsState extends Equatable {
  const RegionsState();

  @override
  List<Object?> get props => [];
}

class RegionsInitial extends RegionsState {}

class RegionsLoading extends RegionsState {}

class RegionsLoaded extends RegionsState {
  final List<RegionEntity> regions;

  const RegionsLoaded(this.regions);

  @override
  List<Object?> get props => [regions];
}

class RegionCreated extends RegionsState {
  final int id;

  const RegionCreated(this.id);

  @override
  List<Object?> get props => [id];
}

class RegionUpdated extends RegionsState {}

class RegionDeleted extends RegionsState {}

class RegionsError extends RegionsState {
  final String message;

  const RegionsError(this.message);

  @override
  List<Object?> get props => [message];
}

