part of 'vouchers_cubit.dart';

abstract class VouchersState extends Equatable {
  const VouchersState();

  @override
  List<Object?> get props => [];
}

class VouchersInitial extends VouchersState {
  const VouchersInitial();
}

class VouchersLoading extends VouchersState {
  const VouchersLoading();
}

class VouchersLoaded extends VouchersState {
  final List<VoucherEntity> vouchers;
  final VoucherType? filter;

  const VouchersLoaded(this.vouchers, {this.filter});

  @override
  List<Object?> get props => [vouchers, filter];
}

class VoucherLoaded extends VouchersState {
  final VoucherEntity voucher;

  const VoucherLoaded(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class VoucherActionInProgress extends VouchersState {
  const VoucherActionInProgress();
}

class VoucherActionSuccess extends VouchersState {
  final VoucherEntity? voucher;
  final String message;

  const VoucherActionSuccess({this.voucher, required this.message});

  @override
  List<Object?> get props => [voucher, message];
}

class VoucherDeleted extends VouchersState {
  final int id;
  final String message;

  const VoucherDeleted({required this.id, required this.message});

  @override
  List<Object?> get props => [id, message];
}

class VoucherNumberGenerated extends VouchersState {
  final VoucherType type;
  final int number;

  const VoucherNumberGenerated({required this.type, required this.number});

  @override
  List<Object?> get props => [type, number];
}

class VouchersFailure extends VouchersState {
  final String message;

  const VouchersFailure(this.message);

  @override
  List<Object?> get props => [message];
}

