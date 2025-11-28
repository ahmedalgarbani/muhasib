import 'package:bloc/bloc.dart';

import 'package:muhasib/features/initial/domain/usecases/check_initial_setup_status.dart';
import 'package:muhasib/features/initial/domain/usecases/mark_initial_setup_complete.dart';
import 'package:muhasib/features/initial/domain/usecases/save_opening_balances.dart';
import 'package:muhasib/features/initial/domain/usecases/get_opening_balances.dart';
import 'package:muhasib/features/initial/domain/entities/opening_balance_entity.dart';

import 'initial_state.dart';

class InitialCubit extends Cubit<InitialState> {
  final CheckInitialSetupStatus checkInitialSetupStatus;
  final MarkInitialSetupComplete markInitialSetupComplete;
  final SaveOpeningBalances saveOpeningBalancesUseCase;
  final GetOpeningBalances getOpeningBalancesUseCase;

  InitialCubit({
    required this.checkInitialSetupStatus,
    required this.markInitialSetupComplete,
    required this.saveOpeningBalancesUseCase,
    required this.getOpeningBalancesUseCase,
  }) : super(InitialInitial());

  Future<void> checkStatus() async {
    emit(InitialLoading());
    try {
      final status = await checkInitialSetupStatus();
      emit(InitialLoaded(isComplete: status.isComplete));
    } catch (e) {
      emit(InitialError('Failed to load onboarding status: $e'));
    }
  }

  Future<void> markSetupComplete() async {
    emit(InitialLoading());
    try {
      await markInitialSetupComplete();
      emit(const InitialLoaded(isComplete: true));
    } catch (e) {
      emit(InitialError('Failed to persist onboarding status: $e'));
    }
  }

  Future<void> saveOpeningBalances(List<OpeningBalanceEntity> balances) async {
    emit(InitialLoading());
    try {
      await saveOpeningBalancesUseCase(balances);
      emit(InitialOpeningBalancesSaved());
    } catch (e) {
      emit(InitialError('فشل في حفظ الأرصدة الافتتاحية: $e'));
    }
  }

  Future<void> loadOpeningBalances() async {
    emit(InitialLoading());
    try {
      final balances = await getOpeningBalancesUseCase();
      emit(InitialOpeningBalancesLoaded(balances));
    } catch (e) {
      emit(InitialError('فشل في تحميل الأرصدة الافتتاحية: $e'));
    }
  }
}
