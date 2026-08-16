import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchases_list_widgets.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchasesListPage extends StatefulWidget {
  const PurchasesListPage({super.key});

  @override
  State<PurchasesListPage> createState() => _PurchasesListPageState();
}

class _PurchasesListPageState extends State<PurchasesListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PurchasesCubit>()..loadPurchaseInvoices(),
      child: Builder(
        builder: (innerContext) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.gray50,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              PurchasesListHeaderWidget(
                searchController: _searchController,
                onSearchChanged: (value) {
                  if (value.isNotEmpty) {
                    innerContext.read<PurchasesCubit>().searchPurchases(value);
                  } else {
                    innerContext.read<PurchasesCubit>().loadPurchaseInvoices();
                  }
                },
                onRefresh: () {
                  innerContext.read<PurchasesCubit>().loadPurchaseInvoices();
                },
              ),
              Expanded(
                child: BlocBuilder<PurchasesCubit, PurchasesState>(
                  builder: (context, state) {
                    if (state is PurchasesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is PurchasesError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is PurchaseInvoicesLoaded) {
                      if (state.invoices.isEmpty) {
                        return const EmptyStateWidget(
                          title: 'لا توجد فواتير مشتريات',
                          subtitle: 'ابدأ بإضافة فاتورة مشتريات جديدة',
                          icon: Icons.receipt_long_outlined,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          innerContext
                              .read<PurchasesCubit>()
                              .loadPurchaseInvoices();
                        },
                        child: ListView.builder(
                          padding: AppConstant.defaultPadding,
                          itemCount: state.invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = state.invoices[index];
                            return PurchasesListInvoiceCardWidget(
                              invoice: invoice,
                              onTap: () async {
                                final result = await innerContext.push(
                                  AppRoutes.purchasesDetail,
                                  extra: invoice,
                                );
                                if (result == true && innerContext.mounted) {
                                  innerContext
                                      .read<PurchasesCubit>()
                                      .loadPurchaseInvoices();
                                }
                              },
                            );
                          },
                        ),
                      );
                    }
                    return const Center(
                      child: Text('ابدأ بتحميل فواتير المشتريات'),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await innerContext.push(
                AppRoutes.purchasesAddInvoice,
              );
              if (result == true && innerContext.mounted) {
                innerContext.read<PurchasesCubit>().loadPurchaseInvoices();
              }
            },
            backgroundColor: AppColors.success,
            icon: const Icon(Icons.add),
            label: const Text('فاتورة جديدة'),
          ),
        ),
      ),
    );
  }
}
