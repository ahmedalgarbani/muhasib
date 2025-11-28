import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/region_repository.dart';

part 'regions_state.dart';

class RegionsCubit extends Cubit<RegionsState> {
  final RegionRepository repository;

  RegionsCubit(this.repository) : super(RegionsInitial());

  Future<void> loadRegions() async {
    emit(RegionsLoading());
    final result = await repository.getRegions();
    result.fold(
      (failure) => emit(RegionsError(failure.message)),
      (regions) => emit(RegionsLoaded(regions)),
    );
  }

  Future<void> loadActiveRegions() async {
    emit(RegionsLoading());
    final result = await repository.getActiveRegions();
    result.fold(
      (failure) => emit(RegionsError(failure.message)),
      (regions) => emit(RegionsLoaded(regions)),
    );
  }

  Future<void> searchRegions(String query) async {
    emit(RegionsLoading());
    final result = await repository.searchRegions(query);
    result.fold(
      (failure) => emit(RegionsError(failure.message)),
      (regions) => emit(RegionsLoaded(regions)),
    );
  }

  Future<void> createRegion(RegionEntity region) async {
    emit(RegionsLoading());
    final result = await repository.createRegion(region);
    await result.fold(
      (failure) async => emit(RegionsError(failure.message)),
      (id) async {
        emit(RegionCreated(id));
        await loadRegions();
      },
    );
  }

  Future<void> updateRegion(RegionEntity region) async {
    emit(RegionsLoading());
    final result = await repository.updateRegion(region);
    await result.fold(
      (failure) async => emit(RegionsError(failure.message)),
      (_) async {
        emit(RegionUpdated());
        await loadRegions();
      },
    );
  }

  Future<void> deleteRegion(int id) async {
    emit(RegionsLoading());
    final result = await repository.deleteRegion(id);
    await result.fold(
      (failure) async => emit(RegionsError(failure.message)),
      (_) async {
        emit(RegionDeleted());
        await loadRegions();
      },
    );
  }
}

