import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/widgets/product_groups_widgets.dart';

class ProductGroupsPage extends StatefulWidget {
  const ProductGroupsPage({super.key});

  @override
  State<ProductGroupsPage> createState() => _ProductGroupsPageState();
}

class _ProductGroupsPageState extends State<ProductGroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductGroupsCubit>()..loadAllGroups(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (innerContext) => Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(innerContext).scaffoldBackgroundColor,
            appBar: const CustomAppBar(),
            body: Column(
              children: [
                ProductGroupsHeaderWidget(
                  searchController: _searchController,
                  onSearchChanged: (value) {
                    if (value.isNotEmpty) {
                      innerContext.read<ProductGroupsCubit>().searchGroups(value);
                    } else {
                      innerContext.read<ProductGroupsCubit>().loadAllGroups();
                    }
                  },
                ),
                Expanded(
                  child: BlocBuilder<ProductGroupsCubit, ProductGroupsState>(
                    builder: (context, state) {
                      if (state is ProductGroupsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ProductGroupsError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (state is ProductGroupsLoaded) {
                        if (state.groups.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'لا توجد مجموعات',
                            subtitle: 'ابدأ بإضافة مجموعة جديدة',
                            icon: Icons.category_outlined,
                          );
                        }
                        return ProductGroupsListWidget(
                          groups: state.groups,
                          onEditGroup: (group) =>
                              _showGroupDialog(innerContext, group: group),
                          onDeleteGroup: (group) =>
                              _showDeleteConfirmation(innerContext, group),
                        );
                      }
                      return const Center(
                        child: Text('ابدأ بإضافة مجموعات المنتجات'),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showGroupDialog(innerContext),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('مجموعة جديدة'),
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupDialog(BuildContext context, {ProductGroupEntity? group}) {
    final nameController = TextEditingController(text: group?.name);
    final descController = TextEditingController(text: group?.statement);

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: Text(group == null ? 'مجموعة جديدة' : 'تعديل المجموعة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextInputField(
                  controller: nameController,
                  hint: 'مثال: إلكترونيات',
                  label: 'اسم المجموعة',
                ),
                const SizedBox(height: 16),
                TextInputField(
                  controller: descController,
                  hint: 'وصف المجموعة',
                  label: 'الوصف (اختياري)',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            HasibButton(
              label: group == null ? 'إضافة' : 'حفظ',
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  AppToast.showError(context, 'الرجاء إدخال اسم المجموعة');
                  return;
                }

                final entity = ProductGroupEntity(
                  id: group?.id,
                  name: nameController.text.trim(),
                  statement: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  isActive: group?.isActive ?? true,
                );

                if (group == null) {
                  context.read<ProductGroupsCubit>().createGroup(entity);
                } else {
                  context.read<ProductGroupsCubit>().updateGroup(entity);
                }

                Navigator.pop(dialogContext);
              },
              variant: HasibButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductGroupEntity group) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CustomDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف مجموعة "${group.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (group.id != null) {
                  context.read<ProductGroupsCubit>().deleteGroup(group.id!);
                }
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
