import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/accounts/accounts.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/account_link_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';


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
      print('Loading accounts...');

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
          // linked: true,
          // linkedTo: 'مصاريف الضرائب الحكومية',
          // linkedAccountNumber: '3221-001',
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
          // linked: true,
          // linkedTo: 'حساب المبيعات الرئيسي',
          // linkedAccountNumber: '411-001',
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

      print('Available accounts loaded: ${availableAccounts.length}');
      context.read<AccountConnectCubit>().loadAllAccountConnects();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing data: $e');
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

      // Check if we already have a connection for this type
      final existingConnect = state.accountConnects.firstWhere(
        (c) => c.accountConnectType == account.connectType,
        orElse: () => const AccountConnectEntity(),
      );

      if (existingConnect.id != null) {
        // Update existing link to the new account
        final updatedConnect = existingConnect.copyWith(
          cId: selectedAccount.cId,
          lastModificationTime: now,
        );
        context.read<AccountConnectCubit>().modifyAccountConnect(
          updatedConnect,
        );
      } else {
        // Create new link for the first time
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
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'ربط الحسابات',
          showBack: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildStatusChip('$linkedCount مرتبط', AppColors.success),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    '$unlinkedCount غير مرتبط',
                    AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: BlocListener<AccountConnectCubit, AccountConnectState>(
          listener: (context, state) {
            if (state is AccountConnectCreated) {
              print(
                'Account connect created successfully with id: ${state.id}',
              );
            } else if (state is AccountConnectError) {
              print('Account connect error: ${state.message}');
              buildSnackbar(context, 'خطأ: ${state.message}');
            } else if (state is AccountConnectDeleted) {
              print('Account connect deleted successfully');
            }
          },
          child: Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextInputField(
                  hint: 'ابحث عن حساب...',
                  textAlign: TextAlign.right,
                  suffixIcon: Icon(Icons.search_outlined),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              // Accounts List
              Expanded(
                child: BlocBuilder<AccountConnectCubit, AccountConnectState>(
                  builder: (context, state) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = filteredAccounts[index];
                        return _checkAccountsState(
                          context,
                          state,
                          account,
                          index,
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

  _checkAccountsState(
    BuildContext ctx,
    AccountConnectState state,
    AccountLinkEntity accountEntity,
    int index,
  ) {
    bool isLinked = false;
    String? linkedAccountName;
    String? linkedAccountCode;

    if (state is AccountConnectsLoaded) {
      final accountConnects = state.accountConnects.where(
        (e) => e.accountConnectType == accountEntity.connectType,
      );
      final accountConnect = accountConnects.isNotEmpty
          ? accountConnects.first
          : null;

      isLinked = accountConnect != null;

      if (isLinked && accountConnect.cId != null) {
        try {
          final linkedAccount = availableAccounts.firstWhere(
            (e) => e.cId == accountConnect.cId,
          );
          linkedAccountName = linkedAccount.name;
          linkedAccountCode = linkedAccount.code;
        } catch (e) {
          // Account not found, mark as unlinked
          isLinked = false;
        }
      }

      return AccountCard(
        account: accountEntity.copyWith(
          linked: isLinked,
          linkedTo: linkedAccountName,
          linkedAccountNumber: linkedAccountCode,
        ),
        onTap: () {
          _showLinkBottomSheet(accountEntity);
        },
      );
    } else if (state is AccountConnectLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (state is AccountConnectError) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          'خطأ: ${state.message}',
          style: TextStyle(color: Colors.red[700]),
        ),
      );
    } else {
      return AccountCard(
        account: accountEntity,
        onTap: () => _showLinkBottomSheet(accountEntity),
      );
    }
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
