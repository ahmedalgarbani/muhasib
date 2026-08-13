part of 'account_link_page.dart';

class AccountStateCheckerWidget extends StatelessWidget {
  final AccountConnectState state;
  final AccountLinkEntity accountEntity;
  final List<AccountEntity> availableAccounts;
  final ValueChanged<AccountLinkEntity> onShowLinkBottomSheet;

  const AccountStateCheckerWidget({
    super.key,
    required this.state,
    required this.accountEntity,
    required this.availableAccounts,
    required this.onShowLinkBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    bool isLinked = false;
    String? linkedAccountName;
    String? linkedAccountCode;

    if (state is AccountConnectsLoaded) {
      final accountConnects = (state as AccountConnectsLoaded).accountConnects.where(
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
          onShowLinkBottomSheet(accountEntity);
        },
      );
    } else if (state is AccountConnectLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppConstant.defaultPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (state is AccountConnectError) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppConstant.defaultPadding,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          'خطأ: ${(state as AccountConnectError).message}',
          style: TextStyle(color: Colors.red[700]),
        ),
      );
    } else {
      return AccountCard(
        account: accountEntity,
        onTap: () => onShowLinkBottomSheet(accountEntity),
      );
    }
  }
}

class AccountLinkStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AccountLinkStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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

class AccountCard extends StatelessWidget {
  final AccountLinkEntity account;
  final VoidCallback onTap;

  const AccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: account.color,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: account.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(account.icon, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.sm6,
                              ),
                            ),
                            child: Text(
                              account.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      account.linked
                          ? LinkedAccountStatus(linkedTo: account.linkedTo)
                          : const UnlinkedAccountStatus(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: AccountLinkActionIcon(linked: account.linked)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LinkedAccountStatus extends StatelessWidget {
  final String? linkedTo;

  const LinkedAccountStatus({super.key, required this.linkedTo});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm10),
      border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 16),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'مرتبط بـ: $linkedTo',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class UnlinkedAccountStatus extends StatelessWidget {
  const UnlinkedAccountStatus({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm10),
      border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1.5),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link_off, color: AppColors.warning, size: 16),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'غير مرتبط - يحتاج إلى ربط',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class AccountLinkActionIcon extends StatelessWidget {
  final bool linked;

  const AccountLinkActionIcon({super.key, required this.linked});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(
      linked ? Icons.swap_horiz : Icons.link,
      color: Colors.white,
      size: 20,
    ),
  );
}

class LinkAccountBottomSheet extends StatefulWidget {
  final AccountLinkEntity account;
  final List<AccountEntity> availableAccounts;

  const LinkAccountBottomSheet({
    super.key,
    required this.account,
    required this.availableAccounts,
  });

  @override
  State<LinkAccountBottomSheet> createState() => _LinkAccountBottomSheetState();
}

class _LinkAccountBottomSheetState extends State<LinkAccountBottomSheet> {
  String searchQuery = '';
  int? selectedAccountId;

  List<AccountEntity> get filteredAccounts {
    if (searchQuery.isEmpty) return widget.availableAccounts;
    return widget.availableAccounts.where((account) {
      return account.name.contains(searchQuery) ||
          account.code.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm10),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ربط حساب ${widget.account.name}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر الحساب من دليل الحسابات لربط العمليات المالية',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextInputField(
              textAlign: TextAlign.right,
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الحسابات المتاحة (${filteredAccounts.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: filteredAccounts.isEmpty
                ? const EmptyStateWidget(
                    title: 'لا توجد حسابات مطابقة للبحث',
                    icon: Icons.search_off,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = filteredAccounts[index];
                      final isSelected = selectedAccountId == account.id;
                      return AccountLinkSelectionItem(
                        account: account,
                        isSelected: isSelected,
                        onTap: () =>
                            setState(() => selectedAccountId = account.id),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      side: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HasibButton(
                    label: 'تأكيد الربط',
                    onPressed: selectedAccountId == null
                        ? null
                        : () {
                            Navigator.pop(context, selectedAccountId);
                          },
                    leading: const Icon(Icons.link),
                    variant: HasibButtonVariant.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountLinkSelectionItem extends StatelessWidget {
  final AccountEntity account;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountLinkSelectionItem({
    super.key,
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue[50]
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      account.code,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey[400])),
                    Text(
                      account.type.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ],
      ),
    ),
  );
}
