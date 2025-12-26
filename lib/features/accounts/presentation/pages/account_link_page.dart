import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/accounts/accounts.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:hasib_lib/form/form_field.dart';
import 'package:hasib_lib/theme/app_colors.dart';

class AccountLinkEntity {
  final int connectType;
  final String name;
  final IconData icon;
  final Color color;
  final String category;
  final bool linked;
  final String? linkedTo;
  final String? linkedAccountNumber;

  AccountLinkEntity({
    required this.connectType,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
    this.linked = false,
    this.linkedTo,
    this.linkedAccountNumber,
  });

  AccountLinkEntity copyWith({
    int? connectType,
    String? name,
    IconData? icon,
    Color? color,
    String? category,
    bool? linked,
    String? linkedTo,
    String? linkedAccountNumber,
  }) {
    return AccountLinkEntity(
      connectType: connectType ?? this.connectType,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      linked: linked ?? this.linked,
      linkedTo: linkedTo ?? this.linkedTo,
      linkedAccountNumber: linkedAccountNumber ?? this.linkedAccountNumber,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(16),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
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
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
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
                          ? _buildLinkedStatus()
                          : _buildUnlinkedStatus(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _buildActionButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'مرتبط بـ: ${account.linkedTo}',
              style: const TextStyle(
                fontSize: 8,
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

  Widget _buildUnlinkedStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1.5,
        ),
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

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: account.linked
            ? null
            : const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
        color: account.linked ? AppColors.error.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: account.linked
            ? Border.all(color: AppColors.error.withOpacity(0.3), width: 2)
            : null,
        boxShadow: account.linked
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Icon(
              account.linked ? Icons.link_off : Icons.link,
              color: account.linked ? AppColors.error : Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Header
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextInputField(
              textAlign: TextAlign.right,
              onChanged: (value) => setState(() => searchQuery = value),

              // decoration: InputDecoration(
              //   hintText: 'ابحث عن حساب...',
              //   prefixIcon: const Icon(Icons.search),
              //   filled: true,
              //   fillColor: Colors.grey[100],
              //   border: OutlineInputBorder(
              //     borderRadius: BorderRadius.circular(16),
              //     borderSide: BorderSide.none,
              //   ),
              //   enabledBorder: OutlineInputBorder(
              //     borderRadius: BorderRadius.circular(16),
              //     borderSide: BorderSide.none,
              //   ),
              //   focusedBorder: OutlineInputBorder(
              //     borderRadius: BorderRadius.circular(16),
              //     borderSide: const BorderSide(
              //       color: AppColors.primary,
              //       width: 2,
              //     ),
              //   ),
              // ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Label
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
          // Accounts List
          Flexible(
            child: filteredAccounts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = filteredAccounts[index];
                      final isSelected = selectedAccountId == account.id;
                      return _buildAccountItem(account, isSelected);
                    },
                  ),
          ),
          // Footer Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
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
                  child: ElevatedButton(
                    onPressed: selectedAccountId == null
                        ? null
                        : () {
                            Navigator.pop(context, selectedAccountId);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: selectedAccountId == null ? 0 : 4,
                      shadowColor: Colors.blue.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link,
                          color: selectedAccountId == null
                              ? Colors.grey[500]
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تأكيد الربط',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedAccountId == null
                                ? Colors.grey[500]
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(AccountEntity account, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedAccountId = account.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          account.type.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, color: Colors.grey[400], size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حسابات مطابقة للبحث',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// screens/account_linking_screen.dart
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
          color: const Color(0xFF14B8A6),
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
      print('Linking account: ${account.name} with selectedId: $selectedId');

      final selectedAccount = availableAccounts.firstWhere(
        (a) => a.id == selectedId,
        orElse: () {
          print('Selected account not found with id: $selectedId');
          throw Exception('Selected account not found');
        },
      );

      print(
        'Selected account: ${selectedAccount.name}, cId: ${selectedAccount.cId}',
      );

      final index = accounts.indexWhere((a) => a.connectType == account.connectType);
      print('Account index: $index');

      if (index == -1) {
        print('Account not found in accounts list');
        buildSnackbar(context, 'خطأ: لم يتم العثور على الحساب');
        return;
      }

      // Create account connect with proper timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      final accountConnect = AccountConnectEntity(
        accountConnectType: account.connectType,
        cId: selectedAccount.cId,
        creationTime: now,
        lastModificationTime: now,
      );

      print('Creating account connect: $accountConnect');
      context.read<AccountConnectCubit>().addAccountConnect(accountConnect);

      buildSnackbar(context, 'تم ربط ${account.name} بنجاح');
    } catch (e) {
      print('Error linking account: $e');
      buildSnackbar(context, 'خطأ في ربط الحساب: $e');
    }
  }

  void _handleUnlinkAccount(
    AccountLinkEntity account,
    List<AccountConnectEntity> accountConnects,
  ) {
    final index = accounts.indexWhere((a) => a.connectType == account.connectType);
    final connectToRemove = accountConnects.firstWhere(
      (connect) => connect.accountConnectType == account.connectType,
      orElse: () => const AccountConnectEntity(),
    );

    if (connectToRemove.id != null) {
      context.read<AccountConnectCubit>().removeAccountConnect(
        connectToRemove.id!,
      );
      buildSnackbar(context, 'تم إلغاء ربط ${account.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              context.pop();
            },
          ),
          title: const Text(
            'ربط الحسابات',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
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
          if (isLinked) {
            _handleUnlinkAccount(accountEntity, state.accountConnects);
          } else {
            _showLinkBottomSheet(accountEntity);
          }
        },
      );
    } else if (state is AccountConnectLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (state is AccountConnectError) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(20),
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

