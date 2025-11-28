import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/cashbox_repository.dart';

part 'cashboxes_state.dart';

class CashboxesCubit extends Cubit<CashboxesState> {
  final CashboxRepository repository;

  CashboxesCubit(this.repository) : super(CashboxesInitial());

  Future<void> loadCashboxes() async {
    emit(CashboxesLoading());
    final result = await repository.getCashboxes();
    result.fold(
      (failure) => emit(CashboxesError(failure.message)),
      (cashboxes) => emit(CashboxesLoaded(cashboxes)),
    );
  }

  Future<void> loadActiveCashboxes() async {
    emit(CashboxesLoading());
    final result = await repository.getActiveCashboxes();
    result.fold(
      (failure) => emit(CashboxesError(failure.message)),
      (cashboxes) => emit(CashboxesLoaded(cashboxes)),
    );
  }

  Future<void> searchCashboxes(String query) async {
    emit(CashboxesLoading());
    final result = await repository.searchCashboxes(query);
    result.fold(
      (failure) => emit(CashboxesError(failure.message)),
      (cashboxes) => emit(CashboxesLoaded(cashboxes)),
    );
  }

  Future<void> createCashbox(CashboxEntity cashbox) async {
    emit(CashboxesLoading());
    final result = await repository.createCashbox(cashbox);
    await result.fold(
      (failure) async => emit(CashboxesError(failure.message)),
      (id) async {
        emit(CashboxCreated(id));
        await loadCashboxes();
      },
    );
  }

  Future<void> updateCashbox(CashboxEntity cashbox) async {
    emit(CashboxesLoading());
    final result = await repository.updateCashbox(cashbox);
    await result.fold(
      (failure) async => emit(CashboxesError(failure.message)),
      (_) async {
        emit(CashboxUpdated());
        await loadCashboxes();
      },
    );
  }

  Future<void> deleteCashbox(int id) async {
    emit(CashboxesLoading());
    final result = await repository.deleteCashbox(id);
    await result.fold(
      (failure) async => emit(CashboxesError(failure.message)),
      (_) async {
        emit(CashboxDeleted());
        await loadCashboxes();
      },
    );
  }

  Future<void> setMainCashbox(int id) async {
    emit(CashboxesLoading());
    final result = await repository.setMainCashbox(id);
    await result.fold(
      (failure) async => emit(CashboxesError(failure.message)),
      (_) async {
        emit(MainCashboxSet());
        await loadCashboxes();
      },
    );
  }
}

