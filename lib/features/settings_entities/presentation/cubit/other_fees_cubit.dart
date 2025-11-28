import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/other_fee_repository.dart';

part 'other_fees_state.dart';

class OtherFeesCubit extends Cubit<OtherFeesState> {
  final OtherFeeRepository repository;

  OtherFeesCubit(this.repository) : super(OtherFeesInitial());

  Future<void> loadOtherFees() async {
    emit(OtherFeesLoading());
    final result = await repository.getOtherFees();
    result.fold(
      (failure) => emit(OtherFeesError(failure.message)),
      (otherFees) => emit(OtherFeesLoaded(otherFees)),
    );
  }

  Future<void> loadActiveOtherFees() async {
    emit(OtherFeesLoading());
    final result = await repository.getActiveOtherFees();
    result.fold(
      (failure) => emit(OtherFeesError(failure.message)),
      (otherFees) => emit(OtherFeesLoaded(otherFees)),
    );
  }

  Future<void> loadOtherFeesByType(int toolType) async {
    emit(OtherFeesLoading());
    final result = await repository.getOtherFeesByType(toolType);
    result.fold(
      (failure) => emit(OtherFeesError(failure.message)),
      (otherFees) => emit(OtherFeesLoaded(otherFees)),
    );
  }

  Future<void> searchOtherFees(String query) async {
    emit(OtherFeesLoading());
    final result = await repository.searchOtherFees(query);
    result.fold(
      (failure) => emit(OtherFeesError(failure.message)),
      (otherFees) => emit(OtherFeesLoaded(otherFees)),
    );
  }

  Future<void> createOtherFee(OtherFeeEntity otherFee) async {
    emit(OtherFeesLoading());
    final result = await repository.createOtherFee(otherFee);
    await result.fold(
      (failure) async => emit(OtherFeesError(failure.message)),
      (id) async {
        emit(OtherFeeCreated(id));
        await loadOtherFees();
      },
    );
  }

  Future<void> updateOtherFee(OtherFeeEntity otherFee) async {
    emit(OtherFeesLoading());
    final result = await repository.updateOtherFee(otherFee);
    await result.fold(
      (failure) async => emit(OtherFeesError(failure.message)),
      (_) async {
        emit(OtherFeeUpdated());
        await loadOtherFees();
      },
    );
  }

  Future<void> deleteOtherFee(int id) async {
    emit(OtherFeesLoading());
    final result = await repository.deleteOtherFee(id);
    await result.fold(
      (failure) async => emit(OtherFeesError(failure.message)),
      (_) async {
        emit(OtherFeeDeleted());
        await loadOtherFees();
      },
    );
  }
}

