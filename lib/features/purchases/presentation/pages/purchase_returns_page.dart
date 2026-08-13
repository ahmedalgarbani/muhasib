import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/pages/select_purchase_for_return_page.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_returns_widgets.dart';

class PurchaseReturnsPage extends StatefulWidget {
  const PurchaseReturnsPage({super.key});

  @override
  State<PurchaseReturnsPage> createState() => _PurchaseReturnsPageState();
}

class _PurchaseReturnsPageState extends State<PurchaseReturnsPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PurchasesCubit>()..loadPurchaseReturns(),
      child: Builder(
        builder: (innerContext) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.gray50,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              PurchaseReturnsHeaderWidget(
                searchController: _searchController,
                onRefresh: () =>
                    innerContext.read<PurchasesCubit>().loadPurchaseReturns(),
              ),
              PurchaseReturnsTabBarWidget(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    BlocBuilder<PurchasesCubit, PurchasesState>(
                      builder: (context, state) {
                        if (state is PurchasesLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is PurchasesError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.message,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                HasibButton(
                                  label: 'إعادة المحاولة',
                                  onPressed: () => innerContext
                                      .read<PurchasesCubit>()
                                      .loadPurchaseReturns(),
                                  icon: Icons.refresh,
                                  variant: HasibButtonVariant.danger,
                                  fullWidth: false,
                                ),
                              ],
                            ),
                          );
                        } else if (state is PurchaseReturnsLoaded) {
                          if (state.returns.isEmpty) {
                            return EmptyStateWidget(
                              title: 'لا توجد مردودات',
                              subtitle: 'لم يتم إنشاء أي مردودات مشتريات بعد',
                              icon: Icons.assignment_return_outlined,
                              iconSize: 64,
                              iconColor: Colors.red.withOpacity(0.3),
                              actionText: 'إنشاء مردود',
                              onActionPressed: () =>
                                  _showCreateReturnDialog(context),
                            );
                          }
                          return PurchaseReturnsListWidget(
                            returns: state.returns,
                            onRefresh: () => innerContext
                                .read<PurchasesCubit>()
                                .loadPurchaseReturns(),
                          );
                        }
                        return const Center(
                          child: Text('ابدأ بتحميل المردودات'),
                        );
                      },
                    ),
                    const PurchaseReturnsStatisticsTabWidget(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                innerContext,
                MaterialPageRoute(
                  builder: (_) => const SelectPurchaseForReturnPage(),
                ),
              ).then((_) {
                innerContext.read<PurchasesCubit>().loadPurchaseReturns();
              });
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.assignment_return, size: 20),
            label: const Text('مردود جديد', style: TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }

  void _showCreateReturnDialog(BuildContext innerContext) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Row(
          children: [
            Icon(Icons.assignment_return, color: Colors.red),
            SizedBox(width: 8),
            Text('إنشاء مردود مشتريات'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الفاتورة المراد إرجاع منتجاتها:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم فتح نموذج لاختيار المنتجات المراد إرجاعها',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          HasibButton(
            label: 'متابعة',
            onPressed: () {
              Navigator.of(context).pop();
              AppToast.showInfo(
                context,
                'سيتم إضافة نموذج إنشاء المردود قريباً',
              );
            },
            icon: Icons.arrow_forward,
            variant: HasibButtonVariant.danger,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
