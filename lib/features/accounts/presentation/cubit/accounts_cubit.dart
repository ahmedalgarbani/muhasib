import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/usecases/create_account.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_account.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_master_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/search_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_account.dart';

part 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  final GetAllAccounts getAllAccounts;
  final GetMasterAccounts getMasterAccounts;
  final CreateAccount createAccount;
  final UpdateAccount updateAccount;
  final DeleteAccount deleteAccount;
  final SearchAccounts searchAccounts;
  List<AccountEntity>? allAccounts;
  AccountsCubit({
    required this.getAllAccounts,
    required this.getMasterAccounts,
    required this.createAccount,
    required this.updateAccount,
    required this.deleteAccount,
    required this.searchAccounts,
  }) : super(AccountsInitial());

  Future<void> loadAllAccounts() async {
    emit(AccountsLoading());

    final result = await getAllAccounts(params: NoParams());

    result.fold(
      (failure) {
        emit(AccountsError(failure.message));
      },
      (accounts) {
        allAccounts = accounts;
        emit(AccountsLoaded(accounts));
      },
    );
  }

  Future<void> loadMasterAccounts() async {
    emit(AccountsLoading());

    final result = await getMasterAccounts(params: NoParams());

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(accounts)),
    );
  }

  Future<void> addAccount(AccountEntity account) async {
    emit(AccountsLoading());

    final result = await createAccount(params: account);

    result.fold((failure) => emit(AccountsError(failure.message)), (accountId) {
      emit(AccountCreated(accountId));
      loadAllAccounts();
    });
  }

  Future<void> modifyAccount(AccountEntity account) async {
    emit(AccountsLoading());

    final result = await updateAccount(params: account);

    result.fold((failure) => emit(AccountsError(failure.message)), (_) {
      emit(AccountUpdated());
      loadAllAccounts();
    });
  }

  Future<void> removeAccount(int accountId) async {
    emit(AccountsLoading());

    final result = await deleteAccount(params: accountId);

    result.fold((failure) => emit(AccountsError(failure.message)), (_) {
      emit(AccountDeleted());
      loadAllAccounts();
    });
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loadAllAccounts();
      return;
    }

    emit(AccountsLoading());

    final result = await searchAccounts(params: query);

    result.fold(
      (failure) => emit(AccountsError(failure.message)),
      (accounts) => emit(AccountsLoaded(accounts)),
    );
  }

  // Alias for loadAllAccounts for compatibility
  Future<void> getAccounts() async {
    await loadAllAccounts();
  }
}
