import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';

part 'account_limits_state.dart';

class AccountLimitsCubit extends Cubit<AccountLimitsState> {
  final AccountLimitService limitService;

  AccountLimitsCubit({required this.limitService})
      : super(AccountLimitsInitial());

  Future<void> loadLimits({String? message}) async {
    emit(AccountLimitsLoading());
    final result = await limitService.getAllAccountLimits();
    result.fold(
      (failure) => emit(AccountLimitsError(failure.message)),
      (limits) => emit(AccountLimitsLoaded(limits, message: message)),
    );
  }

  Future<void> saveLimit(AccountLimitEntity limit) async {
    emit(AccountLimitsLoading());
    final result = await limitService.saveAccountLimit(limit);

    result.fold(
      (failure) => emit(AccountLimitsError(failure.message)),
      (_) => loadLimits(message: 'تم حفظ حد الحساب بنجاح'),
    );
  }

  Future<void> deleteLimit(int id) async {
    emit(AccountLimitsLoading());
    final result = await limitService.deleteAccountLimit(id);

    result.fold(
      (failure) => emit(AccountLimitsError(failure.message)),
      (_) => loadLimits(message: 'تم حذف حد الحساب'),
    );
  }
}
