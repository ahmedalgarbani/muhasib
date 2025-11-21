import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'initial_state.dart';

class InitialCubit extends Cubit<InitialState> {
  InitialCubit() : super(InitialInitial());
}
