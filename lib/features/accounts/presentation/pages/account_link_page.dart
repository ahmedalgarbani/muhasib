import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/accounts.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/account_link_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/core/constant/app_constant.dart';

part 'account_link_widgets.dart';

class AccountLinkingScreen extends StatefulWidget {
  const AccountLinkingScreen({super.key});

  @override
  State<AccountLinkingScreen> createState() => _AccountLinkingScreenState();
}

class _AccountLinkingScreenState extends State<AccountLinkingScreen> {
  String searchQuery = '';
  List<AccountLinkEntity> accounts = [];
  List<AccountEntity> availableAccounts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() async {
    try {
      var cubitInstance = context.read<AccountsCubit>();

      accounts = [
        AccountLinkEntity(
          connectType: 0,
          name: 'البنوك',
          icon: Icons.account_balance,
          color: Colors.blue,
          category: 'أصول',
        ),
        AccountLinkEntity(
          connectType: 1,
          name: 'الصناديق',
          icon: Icons.wallet,
          color: Colors.green,
          category: 'أصول',
        ),
        AccountLinkEntity(
          connectType: 2,
          name: 'العملاء',
          icon: Icons.people,
          color: Colors.purple,
          category: 'أصول',
        ),
        AccountLinkEntity(
          connectType: 3,
          name: 'الموردون',
          icon: Icons.inventory_2,
          color: Colors.orange,
          category: 'خصوم',
        ),
        AccountLinkEntity(
          connectType: 4,
          name: 'الضرائب',
          icon: Icons.description,
          color: Colors.red,
          category: 'خصوم',
        ),
        AccountLinkEntity(
          connectType: 5,
          name: 'المخزون',
          icon: Icons.inventory,
          color: Colors.indigo,
          category: 'أصول',
        ),
        AccountLinkEntity(
          connectType: 6,
          name: 'البضاعة',
          icon: Icons.shopping_cart,
          color: Colors.pink,
          category: 'أصول',
        ),
        AccountLinkEntity(
          connectType: 7,
          name: 'المبيعات',
          icon: Icons.trending_up,
          color: Colors.teal,
          category: 'إيرادات',
        ),
        AccountLinkEntity(
          connectType: 8,
          name: 'الخصم المسموح به',
          icon: Icons.credit_card,
          color: Colors.cyan,
          category: 'مصروفات',
        ),
        AccountLinkEntity(
          connectType: 9,
          name: 'الخصم المكتسب',
          icon: Icons.credit_card,
          color: AppColors.teal500,
          category: 'إيرادات',
        ),
        AccountLinkEntity(
          connectType: 10,
          name: 'المشتريات',
          icon: Icons.shopping_basket,
          color: Colors.amber,
          category: 'مصروفات',
        ),
      ];

      await cubitInstance.loadAllAccounts();
      availableAccounts = cubitInstance.allAccounts ?? [];

      context.read<AccountConnectCubit>().loadAllAccountConnects();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  List<AccountLinkEntity> get filteredAccounts {
    if (searchQuery.isEmpty) return accounts;
    return accounts.where((account) {
      return account.name.contains(searchQuery);
    }).toList();
  }

  int get linkedCount {
    final state = context.read<AccountConnectCubit>().state;
    if (state is AccountConnectsLoaded) {
      return state.accountConnects.length;
    }
    return 0;
  }

  int get unlinkedCount => accounts.length - linkedCount;

  void _showLinkBottomSheet(AccountLinkEntity account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => LinkAccountBottomSheet(
          account: account,
          availableAccounts: availableAccounts,
        ),
      ),
    ).then((selectedId) {
      if (selectedId != null) {
        _handleLinkAccount(account, selectedId);
      }
    });
  }

  void _handleLinkAccount(AccountLinkEntity account, int selectedId) {
    try {
      final state = context.read<AccountConnectCubit>().state;
      if (state is! AccountConnectsLoaded) return;

      final selectedAccount = availableAccounts.firstWhere(
        (a) => a.id == selectedId,
        orElse: () => throw Exception('Selected account not found'),
      );

      final now = DateTime.now().millisecondsSinceEpoch;

      final existingConnect = state.accountConnects.firstWhere(
        (c) => c.accountConnectType == account.connectType,
        orElse: () => const AccountConnectEntity(),
      );

      if (existingConnect.id != null) {
        final updatedConnect = existingConnect.copyWith(
          cId: selectedAccount.cId,
          lastModificationTime: now,
        );
        context.read<AccountConnectCubit>().modifyAccountConnect(
          updatedConnect,
        );
      } else {
        final accountConnect = AccountConnectEntity(
          accountConnectType: account.connectType,
          cId: selectedAccount.cId,
          creationTime: now,
          lastModificationTime: now,
        );
        context.read<AccountConnectCubit>().addAccountConnect(accountConnect);
      }

      buildSnackbar(context, 'تم ربط ${account.name} بنجاح');
    } catch (e) {
      buildSnackbar(context, 'خطأ في ربط الحساب: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'ربط الحسابات',
          showBack: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  AccountLinkStatusChip(
                    label: '$linkedCount مرتبط',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  AccountLinkStatusChip(
                    label: '$unlinkedCount غير مرتبط',
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: BlocListener<AccountConnectCubit, AccountConnectState>(
          listener: (context, state) {
            if (state is AccountConnectError) {
              buildSnackbar(context, 'خطأ: ${state.message}');
            }
          },
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextInputField(
                  hint: 'ابحث عن حساب...',
                  textAlign: TextAlign.right,
                  suffixIcon: const Icon(Icons.search_outlined),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              Expanded(
                child: BlocBuilder<AccountConnectCubit, AccountConnectState>(
                  builder: (context, state) {
                    return ListView.builder(
                      padding: AppConstant.defaultPadding,
                      itemCount: filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = filteredAccounts[index];
                        return AccountStateCheckerWidget(
                          state: state,
                          accountEntity: account,
                          availableAccounts: availableAccounts,
                          onShowLinkBottomSheet: _showLinkBottomSheet,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
