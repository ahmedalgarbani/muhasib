import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/products/domain/entities/product_group_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';

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
            backgroundColor: AppColors.gray50,
            appBar: CustomAppBar(),
            body: Column(
              children: [
                _buildHeader(innerContext),
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
                          return _buildEmptyState();
                        }
                        return _buildGroupsList(innerContext, state.groups);
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

  Widget _buildHeader(BuildContext innerContext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مجموعات المنتجات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          TextInputField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في المجموعات...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                innerContext.read<ProductGroupsCubit>().searchGroups(value);
              } else {
                innerContext.read<ProductGroupsCubit>().loadAllGroups();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(
    BuildContext innerContext,
    List<ProductGroupEntity> groups,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.category, color: AppColors.primary),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: group.statement != null
                ? Text(
                    group.statement!,
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.parentGroupId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      'فرعية',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showGroupDialog(innerContext, group: group);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(innerContext, group);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد مجموعات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة مجموعة جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
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
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(group == null ? 'إضافة' : 'حفظ'),
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
