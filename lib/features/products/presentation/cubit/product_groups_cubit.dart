import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/features/products/domain/repositories/product_group_repository.dart';

part 'product_groups_state.dart';

class ProductGroupsCubit extends Cubit<ProductGroupsState> {
  final ProductGroupRepository repository;

  ProductGroupsCubit(this.repository) : super(ProductGroupsInitial());

  Future<void> loadAllGroups() async {
    emit(ProductGroupsLoading());
    final result = await repository.getAllGroups();
    result.fold(
      (failure) => emit(ProductGroupsError(failure.message)),
      (groups) => emit(ProductGroupsLoaded(groups)),
    );
  }

  Future<void> loadGroupsByParent(int? parentId) async {
    emit(ProductGroupsLoading());
    final result = await repository.getGroupsByParent(parentId);
    result.fold(
      (failure) => emit(ProductGroupsError(failure.message)),
      (groups) => emit(ProductGroupsLoaded(groups)),
    );
  }

  Future<void> searchGroups(String query) async {
    emit(ProductGroupsLoading());
    final result = await repository.searchGroups(query);
    result.fold(
      (failure) => emit(ProductGroupsError(failure.message)),
      (groups) => emit(ProductGroupsLoaded(groups)),
    );
  }

  Future<void> createGroup(ProductGroupEntity group) async {
    emit(ProductGroupsLoading());
    final result = await repository.createGroup(group);
    await result.fold(
      (failure) async => emit(ProductGroupsError(failure.message)),
      (id) async {
        emit(ProductGroupCreated(id));
        await loadAllGroups();
      },
    );
  }

  Future<void> updateGroup(ProductGroupEntity group) async {
    emit(ProductGroupsLoading());
    final result = await repository.updateGroup(group);
    await result.fold(
      (failure) async => emit(ProductGroupsError(failure.message)),
      (_) async {
        emit(ProductGroupUpdated());
        await loadAllGroups();
      },
    );
  }

  Future<void> deleteGroup(int id) async {
    emit(ProductGroupsLoading());
    final result = await repository.deleteGroup(id);
    await result.fold(
      (failure) async => emit(ProductGroupsError(failure.message)),
      (_) async {
        emit(ProductGroupDeleted());
        await loadAllGroups();
      },
    );
  }
}
