import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_form_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_transactions_page.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_color_helper.dart';
import 'package:muhasib/features/accounts/presentation/widgets/accounts_tree_widgets.dart';
import 'package:muhasib/features/accounts/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:muhasib/features/accounts/presentation/widgets/main_card_account.dart';
import 'package:muhasib/features/accounts/presentation/widgets/sub_card_account.dart';
import 'package:muhasib/core/constant/app_constant.dart';

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
      builder: (dialogContext) => CustomDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'حذف',
            onPressed: () {
              context.read<AccountsCubit>().removeAccount(accountId);
              Navigator.pop(dialogContext);
            },
            variant: HasibButtonVariant.danger,
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
                AccountsTreeHeaderWidget(
                  count: accounts.length,
                  showSearch: showSearch,
                  onToggleSearch: _toggleSearch,
                  onSearchQueryChanged: (value) =>
                      setState(() => searchQuery = value),
                ),
                Expanded(
                  child: AccountsTreeContentWidget(
                    state: state,
                    accounts: accounts,
                    onAccountClick: _handleAccountClick,
                    onEditAccount: _showEditAccountDialog,
                    onDeleteAccount: _confirmDeleteAccount,
                    onRetry: () =>
                        context.read<AccountsCubit>().loadAllAccounts(),
                  ),
                ),
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
            return AccountsTreeErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AccountsCubit>().loadAllAccounts(),
            );
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
                    account.masterId == widget.masterAccount.id ||
                    account.masterCId == widget.masterAccount.cId,
              )
              .toList();

          if (childAccounts.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد حسابات فرعية حالياً',
              subtitle: 'يمكنك إضافة حساب فرعي باستخدام زر الإضافة في الأسفل.',
              icon: Icons.folder_open,
            );
          }

          return ListView.builder(
            padding: AppConstant.defaultPadding,
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
      builder: (dialogContext) => CustomDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'حذف',
            onPressed: () {
              context.read<AccountsCubit>().removeAccount(accountId);
              Navigator.pop(dialogContext);
            },
            variant: HasibButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}
