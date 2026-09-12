import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/usecases/create_currency.dart';
import 'package:muhasib/features/currencies/domain/usecases/delete_currency.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_all_currencies.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_currency_by_code.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_currency_by_id.dart';
import 'package:muhasib/features/currencies/domain/usecases/search_currencies.dart';
import 'package:muhasib/features/currencies/domain/usecases/update_currency.dart';
import 'package:muhasib/features/plans/domain/entities/plan_limit.dart';
import 'package:muhasib/features/plans/domain/services/plan_limit_guard.dart';

part 'currencies_state.dart';

class CurrenciesCubit extends Cubit<CurrenciesState> {
  final GetAllCurrencies getAllCurrencies;
  final GetCurrencyById getCurrencyById;
  final GetCurrencyByCode getCurrencyByCode;
  final CreateCurrency createCurrency;
  final UpdateCurrency updateCurrency;
  final DeleteCurrency deleteCurrency;
  final SearchCurrencies searchCurrencies;

  List<CurrencyEntity>? allCurrencies;

  CurrenciesCubit({
    required this.getAllCurrencies,
    required this.getCurrencyById,
    required this.getCurrencyByCode,
    required this.createCurrency,
    required this.updateCurrency,
    required this.deleteCurrency,
    required this.searchCurrencies,
  }) : super(CurrenciesInitial());

  Future<void> loadAllCurrencies() async {
    emit(CurrenciesLoading());
    final result = await getAllCurrencies(params: NoParams());
    result.fold((failure) => emit(CurrenciesError(failure.message)), (
      currencies,
    ) {
      allCurrencies = currencies;
      emit(CurrenciesLoaded(currencies));
    });
  }

  Future<void> addCurrency(CurrencyEntity currency) async {
    final limitError = PlanLimitGuard.check(
      PlanLimit.maxCurrencies,
      allCurrencies?.length ?? 0,
    );
    if (limitError != null) {
      emit(CurrenciesError(limitError));
      return;
    }
    emit(CurrenciesLoading());
    final result = await createCurrency(params: currency);
    result.fold((failure) => emit(CurrenciesError(failure.message)), (id) {
      emit(CurrencyCreated(id));
      loadAllCurrencies();
    });
  }

  Future<void> modifyCurrency(CurrencyEntity currency) async {
    emit(CurrenciesLoading());
    final result = await updateCurrency(params: currency);
    result.fold((failure) => emit(CurrenciesError(failure.message)), (_) {
      emit(CurrencyUpdated());
      loadAllCurrencies();
    });
  }

  Future<void> removeCurrency(int id) async {
    emit(CurrenciesLoading());
    final result = await deleteCurrency(params: id);
    result.fold((failure) => emit(CurrenciesError(failure.message)), (_) {
      emit(CurrencyDeleted());
      loadAllCurrencies();
    });
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loadAllCurrencies();
      return;
    }
    emit(CurrenciesLoading());
    final result = await searchCurrencies(params: query);
    result.fold(
      (failure) => emit(CurrenciesError(failure.message)),
      (currencies) => emit(CurrenciesLoaded(currencies)),
    );
  }
}
