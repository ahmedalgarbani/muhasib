import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';

part 'banks_state.dart';

class BanksCubit extends Cubit<BanksState> {
  final BankRepository repository;

  BanksCubit(this.repository) : super(BanksInitial());

  Future<void> loadBanks() async {
    emit(BanksLoading());
    final result = await repository.getBanks();
    result.fold(
      (failure) => emit(BanksError(failure.message)),
      (banks) => emit(BanksLoaded(banks)),
    );
  }

  Future<void> loadActiveBanks() async {
    emit(BanksLoading());
    final result = await repository.getActiveBanks();
    result.fold(
      (failure) => emit(BanksError(failure.message)),
      (banks) => emit(BanksLoaded(banks)),
    );
  }

  Future<void> searchBanks(String query) async {
    emit(BanksLoading());
    final result = await repository.searchBanks(query);
    result.fold(
      (failure) => emit(BanksError(failure.message)),
      (banks) => emit(BanksLoaded(banks)),
    );
  }

  Future<void> createBank(BankEntity bank) async {
    emit(BanksLoading());
    final result = await repository.createBank(bank);
    await result.fold(
      (failure) async => emit(BanksError(failure.message)),
      (id) async {
        emit(BankCreated(id));
        await loadBanks();
      },
    );
  }

  Future<void> updateBank(BankEntity bank) async {
    emit(BanksLoading());
    final result = await repository.updateBank(bank);
    await result.fold(
      (failure) async => emit(BanksError(failure.message)),
      (_) async {
        emit(BankUpdated());
        await loadBanks();
      },
    );
  }

  Future<void> deleteBank(int id) async {
    emit(BanksLoading());
    final result = await repository.deleteBank(id);
    await result.fold(
      (failure) async => emit(BanksError(failure.message)),
      (_) async {
        emit(BankDeleted());
        await loadBanks();
      },
    );
  }
}

