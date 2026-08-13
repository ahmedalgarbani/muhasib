import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/products/presentation/cubit/item_movements_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/widgets/item_movements_widgets.dart';

class ItemMovementsPage extends StatefulWidget {
  const ItemMovementsPage({super.key});

  @override
  State<ItemMovementsPage> createState() => _ItemMovementsPageState();
}

class _ItemMovementsPageState extends State<ItemMovementsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedProductFilter;
  int? _selectedTypeFilter;
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ItemMovementsCubit>()..loadAllMovements(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.gray50,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            ItemMovementsHeaderWidget(
              searchController: _searchController,
              selectedProductFilter: _selectedProductFilter,
              selectedTypeFilter: _selectedTypeFilter,
              onSearchChanged: (value) {
                if (value.isNotEmpty) {
                  context.read<ItemMovementsCubit>().searchMovements(value);
                } else {
                  context.read<ItemMovementsCubit>().loadAllMovements();
                }
              },
              onSelectDateRange: () => _selectDateRange(context),
              onProductFilterChanged: (value) {
                setState(() => _selectedProductFilter = value);
                if (value != null) {
                  context
                      .read<ItemMovementsCubit>()
                      .loadMovementsByProduct(value);
                } else {
                  context.read<ItemMovementsCubit>().loadAllMovements();
                }
              },
              onTypeFilterChanged: (value) {
                setState(() => _selectedTypeFilter = value);
                if (value != null) {
                  context
                      .read<ItemMovementsCubit>()
                      .loadMovementsByType(value);
                } else {
                  context.read<ItemMovementsCubit>().loadAllMovements();
                }
              },
            ),
            Expanded(
              child: BlocBuilder<ItemMovementsCubit, ItemMovementsState>(
                builder: (context, state) {
                  if (state is ItemMovementsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ItemMovementsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is ItemMovementsLoaded) {
                    if (state.movements.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'لا توجد حركات مخزون',
                        subtitle: 'ستظهر هنا جميع حركات المخزون',
                        icon: Icons.swap_vert_circle_outlined,
                      );
                    }
                    return ItemMovementsListWidget(movements: state.movements);
                  }
                  return const Center(child: Text('لا توجد حركات'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      context.read<ItemMovementsCubit>().loadMovementsByDateRange(
            picked.start,
            picked.end,
          );
    }
  }
}
