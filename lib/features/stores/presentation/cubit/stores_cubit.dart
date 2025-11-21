import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'stores_state.dart';

class StoresCubit extends Cubit<StoresState> {
  StoresCubit() : super(StoresInitial());
}
