import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';

class CashboxesPage extends StatelessWidget {
  const CashboxesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CashboxesCubit>()..loadCashboxes(),
      child: const _CashboxesView(),
    );
  }
}

class _CashboxesView extends StatefulWidget {
  const _CashboxesView();

  @override
  State<_CashboxesView> createState() => _CashboxesViewState();
}

class _CashboxesViewState extends State<_CashboxesView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = false;

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
        title: 'الصناديق',
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<CashboxesCubit>().loadActiveCashboxes();
              } else {
                context.read<CashboxesCubit>().loadCashboxes();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<CashboxesCubit, CashboxesState>(
        listener: (context, state) {
          if (state is CashboxCreated) {
            _showSnackBar(context, 'تم إضافة الصندوق بنجاح', Colors.green);
          } else if (state is CashboxUpdated) {
            _showSnackBar(context, 'تم تحديث الصندوق بنجاح', Colors.green);
          } else if (state is CashboxDeleted) {
            _showSnackBar(context, 'تم حذف الصندوق بنجاح', Colors.green);
          } else if (state is MainCashboxSet) {
            _showSnackBar(context, 'تم تعيين الصندوق الرئيسي بنجاح', Colors.green);
          } else if (state is CashboxesError) {
            _showSnackBar(context, state.message, Colors.red);
          }
        },
        builder: (context, state) {
          if (state is CashboxesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashboxesLoaded) {
            if (state.cashboxes.isEmpty) {
              return _buildEmptyState();
            }
            return _buildCashboxesList(state.cashboxes);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCashboxDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('صندوق جديد'),
        backgroundColor: const Color(0xFF00897B),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildCashboxesList(List<CashboxEntity> cashboxes) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في الصناديق...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CashboxesCubit>().loadCashboxes();
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
                context.read<CashboxesCubit>().loadCashboxes();
              } else {
                context.read<CashboxesCubit>().searchCashboxes(value);
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cashboxes.length,
            itemBuilder: (context, index) => _buildCashboxCard(cashboxes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCashboxCard(CashboxEntity cashbox) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCashboxDialog(context, cashbox: cashbox),
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
                      color: cashbox.isMainFund
                          ? const Color(0xFF1976D2).withOpacity(0.1)
                          : const Color(0xFF00897B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cashbox.isMainFund ? Icons.account_balance_wallet : Icons.point_of_sale,
                      color: cashbox.isMainFund ? const Color(0xFF1976D2) : const Color(0xFF00897B),
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
                                cashbox.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (cashbox.isMainFund)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'رئيسي',
                                  style: TextStyle(
                                    color: Colors.white,
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
                              cashbox.isActive ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: cashbox.isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cashbox.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: cashbox.isActive ? Colors.green : Colors.grey,
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
                      if (!cashbox.isMainFund)
                        const PopupMenuItem(
                          value: 'setMain',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20),
                              SizedBox(width: 8),
                              Text('تعيين كرئيسي'),
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
                        _showCashboxDialog(context, cashbox: cashbox);
                      } else if (value == 'setMain') {
                        _showSetMainDialog(context, cashbox);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, cashbox);
                      }
                    },
                  ),
                ],
              ),
              if (cashbox.currentBalance != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'الرصيد: ${cashbox.currentBalance?.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
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
          Icon(Icons.point_of_sale_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد صناديق',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة صندوق جديد',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showCashboxDialog(BuildContext context, {CashboxEntity? cashbox}) {
    final isEditing = cashbox != null;
    final nameController = TextEditingController(text: cashbox?.name ?? '');
    bool isActive = cashbox?.isActive ?? true;
    bool isMainFund = cashbox?.isMainFund ?? false;

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
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.point_of_sale, color: Color(0xFF00897B), size: 28),
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'تعديل الصندوق' : 'إضافة صندوق جديد'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصندوق *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
                SwitchListTile(
                  title: const Text('صندوق رئيسي'),
                  value: isMainFund,
                  onChanged: (value) => setState(() => isMainFund = value),
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
                  _showSnackBar(context, 'الرجاء إدخال اسم الصندوق', Colors.red);
                  return;
                }

                final newCashbox = CashboxEntity(
                  id: cashbox?.id,
                  name: nameController.text,
                  isActive: isActive,
                  isMainFund: isMainFund,
                  currentBalance: cashbox?.currentBalance,
                );

                Navigator.of(dialogContext).pop();
                if (isEditing) {
                  this.context.read<CashboxesCubit>().updateCashbox(newCashbox);
                } else {
                  this.context.read<CashboxesCubit>().createCashbox(newCashbox);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'تحديث' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetMainDialog(BuildContext context, CashboxEntity cashbox) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFF1976D2), size: 28),
            ),
            const SizedBox(width: 12),
            const Text('تعيين كصندوق رئيسي'),
          ],
        ),
        content: Text('هل تريد تعيين "${cashbox.name}" كصندوق رئيسي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              this.context.read<CashboxesCubit>().setMainCashbox(cashbox.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('تعيين كرئيسي'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CashboxEntity cashbox) {
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
            const Text('حذف الصندوق'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف الصندوق "${cashbox.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              this.context.read<CashboxesCubit>().deleteCashbox(cashbox.id!);
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

