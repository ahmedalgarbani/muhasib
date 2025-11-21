import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecases/usecase.dart' as core_usecase;
import 'package:muhasib/core/usecase/usecases.dart' as account_usecase;
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/domain/usecases/opening_balance_usecases.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_accounts.dart';

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

  OpeningBalanceCubit({
    required this.getAllOpeningBalances,
    required this.getOpeningBalanceById,
    required this.createOpeningBalance,
    required this.updateOpeningBalance,
    required this.deleteOpeningBalance,
    required this.postOpeningBalance,
    required this.generateNextNumber,
    required this.getAllAccounts,
  }) : super(OpeningBalanceInitial());

  List<AccountEntity> availableAccounts = [];
  OpeningBalanceEntity? currentOpeningBalance;
  String currentNumber = '';
  int currentCurrencyId = 1;
  String currentCurrencyCode = 'SAR';

  Future<void> loadOpeningBalances() async {
    emit(OpeningBalanceLoading());
    
    final result = await getAllOpeningBalances(params: core_usecase.NoParams());
    
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
        emit(OpeningBalanceFormReady(
          openingBalance: openingBalance,
          accounts: availableAccounts,
        ));
      },
    );
  }

  Future<void> loadAccounts() async {
    final result = await getAllAccounts(params: account_usecase.NoParams());
    
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (accounts) {
        availableAccounts = accounts.where((account) => !account.isMaster).toList();
        if (state is OpeningBalanceFormReady) {
          emit(OpeningBalanceFormReady(
            openingBalance: currentOpeningBalance,
            accounts: availableAccounts,
          ));
        }
      },
    );
  }

  Future<void> initializeForm() async {
    emit(OpeningBalanceLoading());
    
    // Generate next number
    final numberResult = await generateNextNumber(params: core_usecase.NoParams());
    numberResult.fold(
      (failure) => currentNumber = 'OB-000001',
      (number) => currentNumber = number,
    );
    
    // Load accounts
    await loadAccounts();
    
    // Create empty opening balance
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
    
    emit(OpeningBalanceFormReady(
      openingBalance: currentOpeningBalance,
      accounts: availableAccounts,
    ));
  }

  void addLine(OpeningBalanceLineEntity line) {
    if (currentOpeningBalance == null) return;
    
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    lines.add(line.copyWith(lineNumber: lines.length + 1));
    
    // Calculate totals
    double totalDebit = 0;
    double totalCredit = 0;
    for (final l in lines) {
      totalDebit += l.debit;
      totalCredit += l.credit;
    }
    
    currentOpeningBalance = currentOpeningBalance!.copyWith(
      lines: lines,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
    
    emit(OpeningBalanceFormReady(
      openingBalance: currentOpeningBalance,
      accounts: availableAccounts,
    ));
  }

  void updateLine(int index, OpeningBalanceLineEntity line) {
    if (currentOpeningBalance == null) return;
    
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = line;
      
      // Calculate totals
      double totalDebit = 0;
      double totalCredit = 0;
      for (final l in lines) {
        totalDebit += l.debit;
        totalCredit += l.credit;
      }
      
      currentOpeningBalance = currentOpeningBalance!.copyWith(
        lines: lines,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
      
      emit(OpeningBalanceFormReady(
        openingBalance: currentOpeningBalance,
        accounts: availableAccounts,
      ));
    }
  }

  void removeLine(int index) {
    if (currentOpeningBalance == null) return;
    
    final lines = List<OpeningBalanceLineEntity>.from(currentOpeningBalance!.lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      
      // Renumber lines
      for (int i = 0; i < lines.length; i++) {
        lines[i] = lines[i].copyWith(lineNumber: i + 1);
      }
      
      // Calculate totals
      double totalDebit = 0;
      double totalCredit = 0;
      for (final l in lines) {
        totalDebit += l.debit;
        totalCredit += l.credit;
      }
      
      currentOpeningBalance = currentOpeningBalance!.copyWith(
        lines: lines,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
      
      emit(OpeningBalanceFormReady(
        openingBalance: currentOpeningBalance,
        accounts: availableAccounts,
      ));
    }
  }

  void updateFormData({
    String? number,
    DateTime? entryDate,
    String? description,
    String? notes,
    int? currencyId,
    String? currencyCode,
  }) {
    if (currentOpeningBalance == null) return;
    
    currentOpeningBalance = currentOpeningBalance!.copyWith(
      number: number ?? currentOpeningBalance!.number,
      entryDate: entryDate ?? currentOpeningBalance!.entryDate,
      description: description ?? currentOpeningBalance!.description,
      notes: notes ?? currentOpeningBalance!.notes,
      currencyId: currencyId ?? currentOpeningBalance!.currencyId,
      currencyCode: currencyCode ?? currentOpeningBalance!.currencyCode,
    );
    
    emit(OpeningBalanceFormReady(
      openingBalance: currentOpeningBalance,
      accounts: availableAccounts,
    ));
  }

  Future<void> saveOpeningBalance() async {
    if (currentOpeningBalance == null) return;
    
    if (!currentOpeningBalance!.isBalanced) {
      emit(const OpeningBalanceError('يجب أن يكون إجمالي المدين مساوياً لإجمالي الدائن'));
      return;
    }
    
    if (currentOpeningBalance!.lines.isEmpty) {
      emit(const OpeningBalanceError('يجب إضافة سطر واحد على الأقل'));
      return;
    }
    
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
    
    if (!currentOpeningBalance!.isBalanced) {
      emit(const OpeningBalanceError('يجب أن يكون إجمالي المدين مساوياً لإجمالي الدائن'));
      return;
    }
    
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

  Future<void> deleteCurrentOpeningBalance(int id) async {
    emit(OpeningBalanceDeleting());
    
    final result = await deleteOpeningBalance(params: id);
    
    result.fold(
      (failure) => emit(OpeningBalanceError(failure.message)),
      (_) => emit(OpeningBalanceDeleted()),
    );
  }
}
