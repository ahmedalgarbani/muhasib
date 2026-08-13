import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/widgets/account_color_helper.dart';
import 'package:muhasib/features/accounts/presentation/widgets/main_card_account.dart';
import 'package:muhasib/features/accounts/presentation/widgets/sub_card_account.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class AccountsTreeHeaderWidget extends StatelessWidget {
  final int count;
  final bool showSearch;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchQueryChanged;

  const AccountsTreeHeaderWidget({
    super.key,
    required this.count,
    required this.showSearch,
    required this.onToggleSearch,
    required this.onSearchQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
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
                    onPressed: onToggleSearch,
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
                  child: TextInputField(
                    hint: 'ابحث عن حساب...',
                    autofocus: true,
                    onChanged: onSearchQueryChanged,
                    decoration: InputDecoration(
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
}

class AccountsTreeContentWidget extends StatelessWidget {
  final AccountsState state;
  final List<AccountEntity> accounts;
  final ValueChanged<AccountEntity> onAccountClick;
  final ValueChanged<AccountEntity> onEditAccount;
  final ValueChanged<int> onDeleteAccount;
  final VoidCallback onRetry;

  const AccountsTreeContentWidget({
    super.key,
    required this.state,
    required this.accounts,
    required this.onAccountClick,
    required this.onEditAccount,
    required this.onDeleteAccount,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state is AccountsLoading && accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AccountsError) {
      return AccountsTreeErrorStateWidget(
        message: (state as AccountsError).message,
        onRetry: onRetry,
      );
    }

    if (accounts.isEmpty) {
      return const EmptyStateWidget(
        title: 'لا توجد حسابات حتى الآن',
        subtitle: 'يمكنك إضافة الحساب الأول بالضغط على زر الإضافة.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return ListView.builder(
      padding: AppConstant.defaultPadding,
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final colors = AccountColorHelper.getColors(account);

        return account.isMaster
            ? MainCardAccount(
                account: account,
                onTap: () => onAccountClick(account),
                backgroundColor: colors.background,
                borderColor: colors.border,
                iconColor: colors.icon,
                onEdit: () => onEditAccount(account),
                onDelete: () => onDeleteAccount(account.id!),
              )
            : SubCardAccount(
                account: account,
                backgroundColor: colors.background,
                borderColor: colors.border,
                iconColor: colors.icon,
                onEdit: () => onEditAccount(account),
                onDelete: () => onDeleteAccount(account.id!),
                onTap: () => onAccountClick(account),
              );
      },
    );
  }
}

class AccountsTreeErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AccountsTreeErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            HasibButton(
              label: 'إعادة المحاولة',
              onPressed: onRetry,
              variant: HasibButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
