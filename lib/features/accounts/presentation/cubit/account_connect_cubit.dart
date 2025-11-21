import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/usecases/create_account_connect.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_account_connect.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_account_connect_by_type.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_account_connects.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_account_connect.dart';

part 'account_connect_state.dart';

class AccountConnectCubit extends Cubit<AccountConnectState> {
  final GetAllAccountConnects getAllAccountConnects;
  final CreateAccountConnect createAccountConnect;
  final UpdateAccountConnect updateAccountConnect;
  final DeleteAccountConnect deleteAccountConnect;
  final GetAccountConnectByType getAccountConnectByType;

  AccountConnectCubit({
    required this.getAllAccountConnects,
    required this.createAccountConnect,
    required this.updateAccountConnect,
    required this.deleteAccountConnect,
    required this.getAccountConnectByType,
  }) : super(AccountConnectInitial());

  Future<void> loadAllAccountConnects() async {
    emit(AccountConnectLoading());

    final result = await getAllAccountConnects(params: NoParams());

    result.fold(
      (failure) => emit(AccountConnectError(failure.message)),
      (accountConnects) => emit(AccountConnectsLoaded(accountConnects)),
    );
  }

  Future<void> addAccountConnect(AccountConnectEntity accountConnect) async {
    print('AccountConnectCubit: Adding account connect: $accountConnect');
    emit(AccountConnectLoading());

    final result = await createAccountConnect(params: accountConnect);

    result.fold(
      (failure) {
        print(
          'AccountConnectCubit: Error creating account connect: ${failure.message}',
        );
        emit(AccountConnectError(failure.message));
      },
      (id) {
        print('AccountConnectCubit: Account connect created with id: $id');
        emit(AccountConnectCreated(id));
        loadAllAccountConnects();
      },
    );
  }

  Future<void> modifyAccountConnect(AccountConnectEntity accountConnect) async {
    emit(AccountConnectLoading());

    final result = await updateAccountConnect(params: accountConnect);

    result.fold((failure) => emit(AccountConnectError(failure.message)), (_) {
      emit(AccountConnectUpdated());
      loadAllAccountConnects();
    });
  }

  Future<void> removeAccountConnect(int id) async {
    emit(AccountConnectLoading());

    final result = await deleteAccountConnect(params: id);

    result.fold((failure) => emit(AccountConnectError(failure.message)), (_) {
      emit(AccountConnectDeleted());
      loadAllAccountConnects();
    });
  }

  Future<AccountConnectEntity?> getConnectByType(int type) async {
    final result = await getAccountConnectByType(params: type);

    return result.fold((failure) => null, (accountConnect) => accountConnect);
  }
}
