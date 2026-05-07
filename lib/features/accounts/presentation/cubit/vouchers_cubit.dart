import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';
import '../../domain/entities/voucher_entity.dart';
import '../../domain/usecases/add_voucher.dart';
import '../../domain/usecases/delete_voucher.dart';
import '../../domain/usecases/generate_voucher_number.dart';
import '../../domain/usecases/get_voucher_by_id.dart';
import '../../domain/usecases/get_vouchers.dart';
import '../../domain/usecases/update_voucher.dart';

part 'vouchers_state.dart';

class VouchersCubit extends Cubit<VouchersState> {
  VouchersCubit({
    required this.getVouchersUseCase,
    required this.getVoucherByIdUseCase,
    required this.addVoucherUseCase,
    required this.updateVoucherUseCase,
    required this.deleteVoucherUseCase,
    required this.generateVoucherNumberUseCase,
    required this.limitInterceptor,
  }) : super(const VouchersInitial());

  final GetVouchersUseCase getVouchersUseCase;
  final GetVoucherByIdUseCase getVoucherByIdUseCase;
  final AddVoucherUseCase addVoucherUseCase;
  final UpdateVoucherUseCase updateVoucherUseCase;
  final DeleteVoucherUseCase deleteVoucherUseCase;
  final GenerateVoucherNumberUseCase generateVoucherNumberUseCase;
  final AccountLimitInterceptor limitInterceptor;

  VoucherType? _currentFilter;

  Future<void> loadVouchers({VoucherType? type}) async {
    _currentFilter = type;
    emit(const VouchersLoading());
    final result = await getVouchersUseCase(
      params: VoucherFilterParams(type: type),
    );

    result.fold(
      (failure) => emit(VouchersFailure(failure.message)),
      (vouchers) => emit(VouchersLoaded(vouchers, filter: type)),
    );
  }

  Future<void> fetchVoucher(int id) async {
    emit(const VouchersLoading());
    final result = await getVoucherByIdUseCase(params: id);

    result.fold(
      (failure) => emit(VouchersFailure(failure.message)),
      (voucher) => emit(VoucherLoaded(voucher)),
    );
  }

  Future<void> saveVoucher(VoucherEntity voucher) async {
    emit(const VoucherActionInProgress());

    try {
      // 1. التحقق من السقوف المالية باستخدام المعترض للحساب الرئيسي
      for (final line in voucher.lines) {
        if (line.accountId == null) continue;
        
        final limitCheck = await limitInterceptor.validateVoucher(
          fromAccountId: voucher.type == VoucherType.payment ? voucher.accountId : line.accountId!,
          toAccountId: voucher.type == VoucherType.payment ? line.accountId! : voucher.accountId,
          amount: line.amount ?? 0,
          currencyId: voucher.currencyId ?? 1,
        );

        bool hasStopped = false;
        limitCheck.fold(
          (failure) {
            emit(VouchersFailure(failure.message));
            hasStopped = true;
          },
          (_) => null,
        );
        
        if (hasStopped) return;
      }

      final isNew = voucher.id == null;
      final result = isNew
          ? await addVoucherUseCase(params: voucher)
          : await updateVoucherUseCase(params: voucher);

      await result.fold<Future<void>>(
        (failure) async => emit(VouchersFailure(failure.message)),
        (value) async {
          final voucherId = isNew ? value as int : voucher.id!;
          final fetchResult = await getVoucherByIdUseCase(params: voucherId);

          fetchResult.fold(
            (failure) async => emit(
              VoucherActionSuccess(
                message: isNew ? 'تم حفظ السند بنجاح' : 'تم تحديث السند بنجاح',
              ),
            ),
            (savedVoucher) async => emit(
              VoucherActionSuccess(
                voucher: savedVoucher,
                message: isNew ? 'تم حفظ السند بنجاح' : 'تم تحديث السند بنجاح',
              ),
            ),
          );
        },
      );
    } catch (e) {
      emit(VouchersFailure('خطأ غير متوقع في حفظ السند: ${e.toString()}'));
    }
  }

  Future<void> removeVoucher(int id) async {
    emit(const VoucherActionInProgress());
    final result = await deleteVoucherUseCase(params: id);

    await result.fold<Future<void>>(
      (failure) async => emit(VouchersFailure(failure.message)),
      (_) async {
        emit(VoucherDeleted(id: id, message: 'تم حذف السند بنجاح'));
        await loadVouchers(type: _currentFilter);
      },
    );
  }

  Future<void> refreshNumber(VoucherType type) async {
    final result = await generateVoucherNumberUseCase(params: type);

    result.fold(
      (failure) => emit(VouchersFailure(failure.message)),
      (number) => emit(VoucherNumberGenerated(type: type, number: number)),
    );
  }
}
