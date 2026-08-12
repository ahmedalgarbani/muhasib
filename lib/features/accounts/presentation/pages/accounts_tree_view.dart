import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_form_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_transactions_page.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_color_helper.dart';
import 'package:muhasib/features/accounts/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:muhasib/features/accounts/presentation/widgets/main_card_account.dart';
import 'package:muhasib/features/accounts/presentation/widgets/sub_card_account.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';

class AccountsTreeScreen extends StatelessWidget {
  const AccountsTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountsTreeView();
  }
}

class AccountsTreeView extends StatefulWidget {
  const AccountsTreeView({super.key});

  @override
  State<AccountsTreeView> createState() => _AccountsTreeViewState();
}

class _AccountsTreeViewState extends State<AccountsTreeView> {
  String searchQuery = '';
  bool showSearch = false;

  @override
  void initState() {
    super.initState();
    context.read<AccountsCubit>().loadAllAccounts();
  }

  void _toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      if (!showSearch) {
        searchQuery = '';
      }
    });
  }

  void _handleAccountClick(AccountEntity account) {
    if (account.isMaster) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubAccountsPage(masterAccount: account),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountTransactionsPage(account: account),
        ),
      );
    }
  }

  void _showAddAccountDialog({AccountEntity? masterAccount}) {
    showAddAccountBottomSheet(context, masterAccount: masterAccount);
  }

  void _showEditAccountDialog(AccountEntity account) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountFormPage(account: account)),
    ).then((_) {
      context.read<AccountsCubit>().loadAllAccounts();
    });
  }

  void _confirmDeleteAccount(int accountId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AccountsCubit>().removeAccount(accountId);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'دليل الحسابات'),
      body: BlocListener<AccountsCubit, AccountsState>(
        listener: (context, state) {
          if (state is AccountCreated ||
              state is AccountUpdated ||
              state is AccountDeleted) {
            context.read<AccountsCubit>().loadAllAccounts();
          }
        },
        child: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            final accounts = _filterRootAccounts(state);

            return Column(
              children: [
                _buildHeader(state, accounts.length),
                Expanded(child: _buildContent(state, accounts)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<AccountEntity> _filterRootAccounts(AccountsState state) {
    final cubit = context.read<AccountsCubit>();
    final source = state is AccountsLoaded
        ? state.accounts
        : (cubit.allAccounts ?? const <AccountEntity>[]);

    // Default view: only root accounts (masterId == null)
    // Search view: search across ALL accounts to ensure seeded accounts that
    // have incorrect masterId but correct masterCId are still discoverable.
    if (searchQuery.isEmpty) {
      return source.where((account) => account.masterId == null).toList();
    }

    final query = searchQuery.trim();
    return source
        .where(
          (account) =>
              account.name.contains(query) || account.code.contains(query),
        )
        .toList();
  }

  Widget _buildHeader(AccountsState state, int count) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (innerContext) => IconButton(
                      onPressed: () => Scaffold.of(innerContext).openDrawer(),
                      icon: const Icon(Icons.menu, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'شجرة الحسابات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$count حساباً',
                          style: const TextStyle(color: AppColors.blue200),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: const Icon(Icons.search, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: showSearch
                          ? Colors.white.withOpacity(0.2)
                          : null,
                    ),
                  ),
                ],
              ),
              if (showSearch)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن حساب...',
                      hintStyle: const TextStyle(color: AppColors.blue200),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.blue200,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AccountsState state, List<AccountEntity> accounts) {
    if (state is AccountsLoading && accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AccountsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.read<AccountsCubit>().loadAllAccounts(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (accounts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final colors = AccountColorHelper.getColors(account);

        return account.isMaster
            ? MainCardAccount(
                account: account,
                onTap: () => _handleAccountClick(account),
                backgroundColor: colors.background,
                borderColor: colors.border,
                iconColor: colors.icon,
                onEdit: () => _showEditAccountDialog(account),
                onDelete: () => _confirmDeleteAccount(account.id!),
              )
            : SubCardAccount(
                account: account,
                backgroundColor: colors.background,
                borderColor: colors.border,
                iconColor: colors.icon,
                onEdit: () => _showEditAccountDialog(account),
                onDelete: () => _confirmDeleteAccount(account.id!),
                onTap: () => _handleAccountClick(account),
              );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حسابات حتى الآن',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إضافة الحساب الأول بالضغط على زر الإضافة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SubAccountsPage extends StatefulWidget {
  final AccountEntity masterAccount;

  const SubAccountsPage({super.key, required this.masterAccount});

  @override
  State<SubAccountsPage> createState() => _SubAccountsPageState();
}

class _SubAccountsPageState extends State<SubAccountsPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AccountsCubit>();
    if (cubit.allAccounts == null) {
      cubit.loadAllAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'الحسابات الفرعية - ${widget.masterAccount.name}',
        showBack: true,
      ),
      body: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, state) {
          if (state is AccountsError) {
            return _buildErrorState(state.message);
          }

          final cubit = context.read<AccountsCubit>();
          final allAccounts = state is AccountsLoaded
              ? state.accounts
              : (cubit.allAccounts ?? []);

          if (state is AccountsLoading && allAccounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final childAccounts = allAccounts
              .where(
                (account) =>
                    // Primary linkage
                    account.masterId == widget.masterAccount.id ||
                    // Fallback linkage (used by seeders)
                    account.masterCId == widget.masterAccount.cId,
              )
              .toList();

          if (childAccounts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: childAccounts.length,
            itemBuilder: (context, index) {
              final account = childAccounts[index];
              final colors = AccountColorHelper.getColors(account);

              if (account.isMaster) {
                return MainCardAccount(
                  account: account,
                  onTap: () => _handleAccountClick(account),
                  backgroundColor: colors.background,
                  borderColor: colors.border,
                  iconColor: colors.icon,
                  onEdit: () => _showEditAccountDialog(account),
                  onDelete: () => _confirmDeleteAccount(account.id!),
                );
              }

              return SubCardAccount(
                account: account,
                backgroundColor: colors.background,
                borderColor: colors.border,
                iconColor: colors.icon,
                onEdit: () => _showEditAccountDialog(account),
                onDelete: () => _confirmDeleteAccount(account.id!),
                onTap: () => _handleAccountClick(account),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddAccountBottomSheet(
            context,
            masterAccount: widget.masterAccount,
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleAccountClick(AccountEntity account) {
    if (account.isMaster) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubAccountsPage(masterAccount: account),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountTransactionsPage(account: account),
        ),
      );
    }
  }

  void _showEditAccountDialog(AccountEntity account) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountFormPage(account: account)),
    ).then((_) {
      context.read<AccountsCubit>().loadAllAccounts();
    });
  }

  void _confirmDeleteAccount(int accountId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AccountsCubit>().removeAccount(accountId);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.amber100,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warning, width: 3),
              ),
              child: const Icon(
                Icons.folder_open,
                size: 60,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا توجد حسابات فرعية حالياً',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'يمكنك إضافة حساب فرعي باستخدام زر الإضافة في الأسفل.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AccountsCubit>().loadAllAccounts(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
