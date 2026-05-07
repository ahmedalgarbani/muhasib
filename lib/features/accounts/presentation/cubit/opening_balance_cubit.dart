import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecases/usecase.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/domain/usecases/opening_balance_usecases.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_accounts.dart';
import 'package:muhasib/core/usecase/usecases.dart' as old_usecases;

part 'opening_balance_state.dart';

class OpeningBalanceCubit extends Cubit<OpeningBalanceState> {
  final GetAllOpeningBalances getAllOpeningBalances;
  final GetOpeningBalanceById getOpeningBalanceById;
  final CreateOpeningBalance createOpeningBalance;
  final UpdateOpeningBalance updateOpeningBalance;
  final DeleteOpeningBalance deleteOpeningBalance;
  final PostOpeningBalance postOpeningBalance;
  final GenerateNextOpeningBalanceNumber generateNextNumber;
  final GetAllAccounts getAllAccounts;
  final AccountLimitInterceptor limitInterceptor;

  OpeningBalanceCubit({
    required this.getAllOpeningBalances,
    required this.getOpeningBalanceById,
    required this.createOpeningBalance,
    required this.updateOpeningBalance,
    required this.deleteOpeningBalance,
    required this.postOpeningBalance,
    required this.generateNextNumber,
    required this.getAllAccounts,
    required this.limitInterceptor,
  }) : super(OpeningBalanceInitial());

  List<AccountEntity> availableAccounts = [];
  OpeningBalanceEntity? currentOpeningBalance;
  String currentNumber = '';
  int currentCurrencyId = 1;
  String currentCurrencyCode = 'SAR';

  Future<void> loadOpeningBalances() async {
    emit(OpeningBalanceLoading());
    final result = await getAllOpeningBalances(params: NoParams());
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (openingBalances) => emit(OpeningBalancesLoaded(openingBalances)),
    );
  }

  Future<void> loadOpeningBalance(int id) async {
    emit(OpeningBalanceLoading());
    final result = await getOpeningBalanceById(params: id);
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (openingBalance) {
        currentOpeningBalance = openingBalance;
        emit(OpeningBalanceFormReady(openingBalance: openingBalance, accounts: availableAccounts));
      },
    );
  }

  Future<void> loadAccounts() async {
    final result = await getAllAccounts(params: old_usecases.NoParams());
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (accounts) {
        availableAccounts = accounts.where((account) => !account.isMaster).toList();
        if (state is OpeningBalanceFormReady) {
          emit(OpeningBalanceFormReady(openingBalance: currentOpeningBalance, accounts: availableAccounts));
        }
      },
    );
  }

  Future<void> initializeForm() async {
    emit(OpeningBalanceLoading());
    final numberResult = await generateNextNumber(params: NoParams());
    numberResult.fold(
      (failure) => currentNumber = 'OB-000001',
      (number) => currentNumber = number,
    );
    await loadAccounts();
    currentOpeningBalance = OpeningBalanceEntity(
      number: currentNumber,
      entryDate: DateTime.now(),
      description: 'رصيد افتتاحي',
      currencyId: currentCurrencyId,
      currencyCode: currentCurrencyCode,
      totalDebit: 0,
      totalCredit: 0,
      lines: [],
    );
    emit(OpeningBalanceFormReady(openingBalance: currentOpeningBalance, accounts: availableAccounts));
  }

  void addLine(OpeningBalanceLineEntity line) {
    if (currentOpeningBalance == null) return;
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    lines.add(line.copyWith(lineNumber: lines.length + 1));
    _calcAndEmit(lines);
  }

  void updateLine(int index, OpeningBalanceLineEntity line) {
    if (currentOpeningBalance == null) return;
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = line;
      _calcAndEmit(lines);
    }
  }

  void removeLine(int index) {
    if (currentOpeningBalance == null) return;
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      for (int i = 0; i < lines.length; i++) {
        lines[i] = lines[i].copyWith(lineNumber: i + 1);
      }
      _calcAndEmit(lines);
    }
  }

  void _calcAndEmit(List<OpeningBalanceLineEntity> lines) {
    double totalDebit = 0;
    double totalCredit = 0;
    for (final l in lines) {
      totalDebit += l.debit;
      totalCredit += l.credit;
    }
    currentOpeningBalance = currentOpeningBalance!.copyWith(lines: lines, totalDebit: totalDebit, totalCredit: totalCredit);
    emit(OpeningBalanceFormReady(openingBalance: currentOpeningBalance, accounts: availableAccounts));
  }

  void updateFormData({String? number, DateTime? entryDate, String? description, String? notes}) {
    if (currentOpeningBalance == null) return;
    currentOpeningBalance = currentOpeningBalance!.copyWith(
      number: number ?? currentOpeningBalance!.number,
      entryDate: entryDate ?? currentOpeningBalance!.entryDate,
      description: description ?? currentOpeningBalance!.description,
      notes: notes ?? currentOpeningBalance!.notes,
    );
    emit(OpeningBalanceFormReady(openingBalance: currentOpeningBalance, accounts: availableAccounts));
  }

  Future<void> saveOpeningBalance() async {
    if (currentOpeningBalance == null) return;
    if (!currentOpeningBalance!.isBalanced) {
      emit(const OpeningBalanceError('يجب أن يكون إجمالي المدين مساوياً لإجمالي الدائن'));
      return;
    }

    // 1. فحص سقوف الحسابات (التدقيق الجديد)
    final lines = currentOpeningBalance!.lines.map((l) => JournalEntryLineValidation(
      accountId: l.accountId,
      debitAmount: l.debit,
      creditAmount: l.credit,
      currencyId: currentOpeningBalance!.currencyId,
    )).toList();

    final limitCheck = await limitInterceptor.validateJournalEntry(lines: lines);
    
    bool hasStopped = false;
    limitCheck.fold(
      (failure) {
        emit(OpeningBalanceError(failure.message));
        hasStopped = true;
      },
      (_) => null,
    );

    if (hasStopped) return;

    emit(OpeningBalanceSaving());
    final result = currentOpeningBalance!.id == null
        ? await createOpeningBalance(params: currentOpeningBalance!)
        : await updateOpeningBalance(params: currentOpeningBalance!);
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (_) => emit(OpeningBalanceSaved()),
    );
  }

  Future<void> postCurrentOpeningBalance() async {
    if (currentOpeningBalance == null || currentOpeningBalance!.id == null) return;
    emit(OpeningBalancePosting());
    final result = await postOpeningBalance(params: currentOpeningBalance!.id!);
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (_) {
        currentOpeningBalance = currentOpeningBalance!.copyWith(isPosted: true);
        emit(OpeningBalancePosted());
      },
    );
  }
}
