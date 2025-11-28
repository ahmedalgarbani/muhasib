import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/other_fees_cubit.dart';

class OtherFeesPage extends StatelessWidget {
  const OtherFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<OtherFeesCubit>()..loadOtherFees(),
      child: const _OtherFeesView(),
    );
  }
}

class _OtherFeesView extends StatefulWidget {
  const _OtherFeesView();

  @override
  State<_OtherFeesView> createState() => _OtherFeesViewState();
}

class _OtherFeesViewState extends State<_OtherFeesView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = false;

  static const List<String> _toolTypes = ['مصروفات', 'إيرادات', 'أخرى'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: 'أدوات أخرى',
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<OtherFeesCubit>().loadActiveOtherFees();
              } else {
                context.read<OtherFeesCubit>().loadOtherFees();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<OtherFeesCubit, OtherFeesState>(
        listener: (context, state) {
          if (state is OtherFeeCreated) {
            _showSnackBar(context, 'تم إضافة الأداة بنجاح', Colors.green);
          } else if (state is OtherFeeUpdated) {
            _showSnackBar(context, 'تم تحديث الأداة بنجاح', Colors.green);
          } else if (state is OtherFeeDeleted) {
            _showSnackBar(context, 'تم حذف الأداة بنجاح', Colors.green);
          } else if (state is OtherFeesError) {
            _showSnackBar(context, state.message, Colors.red);
          }
        },
        builder: (context, state) {
          if (state is OtherFeesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OtherFeesLoaded) {
            if (state.otherFees.isEmpty) {
              return _buildEmptyState();
            }
            return _buildOtherFeesList(state.otherFees);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOtherFeeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('أداة جديدة'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildOtherFeesList(List<OtherFeeEntity> otherFees) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في الأدوات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<OtherFeesCubit>().loadOtherFees();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                context.read<OtherFeesCubit>().loadOtherFees();
              } else {
                context.read<OtherFeesCubit>().searchOtherFees(value);
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherFees.length,
            itemBuilder: (context, index) => _buildOtherFeeCard(otherFees[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFeeCard(OtherFeeEntity otherFee) {
    final typeColors = [Colors.red, Colors.green, Colors.blue];
    final typeIcons = [Icons.trending_down, Icons.trending_up, Icons.more_horiz];
    final typeIndex = otherFee.toolType.clamp(0, 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOtherFeeDialog(context, otherFee: otherFee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColors[typeIndex].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      typeIcons[typeIndex],
                      color: typeColors[typeIndex],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherFee.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColors[typeIndex].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _toolTypes[typeIndex],
                                style: TextStyle(
                                  color: typeColors[typeIndex],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              otherFee.isActive ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: otherFee.isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              otherFee.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: otherFee.isActive ? Colors.green : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
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
                        _showOtherFeeDialog(context, otherFee: otherFee);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, otherFee);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد أدوات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة أداة جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showOtherFeeDialog(BuildContext context, {OtherFeeEntity? otherFee}) {
    final isEditing = otherFee != null;
    final nameController = TextEditingController(text: otherFee?.name ?? '');
    bool isActive = otherFee?.isActive ?? true;
    int toolType = otherFee?.toolType ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build, color: Color(0xFF9C27B0), size: 28),
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'تعديل الأداة' : 'إضافة أداة جديدة'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الأداة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: toolType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الأداة',
                    border: OutlineInputBorder(),
                  ),
                  items: _toolTypes.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => toolType = value ?? 0),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  _showSnackBar(context, 'الرجاء إدخال اسم الأداة', Colors.red);
                  return;
                }

                final newOtherFee = OtherFeeEntity(
                  id: otherFee?.id,
                  name: nameController.text,
                  isActive: isActive,
                  toolType: toolType,
                );

                Navigator.of(dialogContext).pop();
                if (isEditing) {
                  this.context.read<OtherFeesCubit>().updateOtherFee(newOtherFee);
                } else {
                  this.context.read<OtherFeesCubit>().createOtherFee(newOtherFee);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'تحديث' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, OtherFeeEntity otherFee) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('حذف الأداة'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الأداة "${otherFee.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              this.context.read<OtherFeesCubit>().deleteOtherFee(otherFee.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

