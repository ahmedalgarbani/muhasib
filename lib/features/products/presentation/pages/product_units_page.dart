import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';
import 'package:muhasib/features/products/domain/entities/product_unit_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';

class ProductUnitsPage extends StatefulWidget {
  const ProductUnitsPage({Key? key}) : super(key: key);

  @override
  State<ProductUnitsPage> createState() => _ProductUnitsPageState();
}

class _ProductUnitsPageState extends State<ProductUnitsPage> {
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
      create: (context) => getIt<ProductUnitsCubit>()..loadAllUnits(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF9FAFB),
          endDrawer: const MainAppDrawer(),
          appBar: CustomAppBar(
            onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
                  builder: (context, state) {
                    if (state is ProductUnitsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductUnitsError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProductUnitsLoaded) {
                      if (state.units.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildUnitsList(state.units);
                    }
                    return const Center(
                      child: Text('ابدأ بإضافة وحدات القياس'),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUnitDialog(context),
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.add),
            label: const Text('وحدة جديدة'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'وحدات القياس',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الوحدات...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                context.read<ProductUnitsCubit>().searchUnits(value);
              } else {
                context.read<ProductUnitsCubit>().loadAllUnits();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(List<ProductUnitEntity> units) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.square_foot,
                color: Color(0xFF10B981),
              ),
            ),
            title: Row(
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    unit.short,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'معامل التحويل: ${unit.conversionFactor}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!unit.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'غير نشط',
                      style: TextStyle(fontSize: 12, color: Colors.red),
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
                      _showUnitDialog(context, unit: unit);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, unit);
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
          Icon(
            Icons.square_foot_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد وحدات قياس',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة وحدة قياس جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnitDialog(BuildContext context, {ProductUnitEntity? unit}) {
    final nameController = TextEditingController(text: unit?.name);
    final shortController = TextEditingController(text: unit?.short);
    final factorController = TextEditingController(
      text: unit?.conversionFactor.toString() ?? '1.0',
    );
    bool isActive = unit?.isActive ?? true;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(unit == null ? 'وحدة جديدة' : 'تعديل الوحدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الوحدة',
                      hintText: 'مثال: كيلوجرام',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: shortController,
                    decoration: const InputDecoration(
                      labelText: 'الاختصار',
                      hintText: 'مثال: كجم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: factorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'معامل التحويل',
                      hintText: 'مثال: 1.0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
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
                  if (nameController.text.trim().isEmpty ||
                      shortController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إدخال اسم الوحدة والاختصار'),
                      ),
                    );
                    return;
                  }
                  
                  final factor = double.tryParse(factorController.text) ?? 1.0;
                  
                  final entity = ProductUnitEntity(
                    id: unit?.id,
                    name: nameController.text.trim(),
                    short: shortController.text.trim(),
                    conversionFactor: factor,
                    isActive: isActive,
                  );
                  
                  if (unit == null) {
                    context.read<ProductUnitsCubit>().createUnit(entity);
                  } else {
                    context.read<ProductUnitsCubit>().updateUnit(entity);
                  }
                  
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: Text(unit == null ? 'إضافة' : 'حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductUnitEntity unit) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف وحدة "${unit.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (unit.id != null) {
                  context.read<ProductUnitsCubit>().deleteUnit(unit.id!);
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
