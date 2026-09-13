import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/enums/invoice_payment_status.dart';
import 'package:muhasib/core/enums/sort_options.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/error_state_card.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/pressable_scale.dart';
import 'package:muhasib/core/widgets/stat_card.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/bill_models.dart';

class SalePageBody extends StatefulWidget {
  const SalePageBody({super.key});

  @override
  State<SalePageBody> createState() => _SalePageBodyState();
}

class _SalePageBodyState extends State<SalePageBody> {
  @override
  void initState() {
    super.initState();
    context.read<SalesCubit>().loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return const SalesBillsScreen();
  }
}

class SalesBillsScreen extends StatefulWidget {
  const SalesBillsScreen({super.key});

  @override
  State<SalesBillsScreen> createState() => _SalesBillsScreenState();
}

class _SalesBillsScreenState extends State<SalesBillsScreen> {
  String _searchQuery = "";
  bool _filterOpen = false;
  String _sortBy = "date-desc";

  void _toggleFilterOpen() {
    setState(() {
      _filterOpen = !_filterOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<SalesCubit, SalesState>(
          builder: (context, state) {
            if (state is SalesLoading) {
              return _LoadingView();
            } else if (state is SalesError) {
              return Center(
                child: ErrorStateCard(
                  message: state.message,
                  onRetry: () => context.read<SalesCubit>().loadInvoices(),
                ),
              );
            } else if (state is SalesLoaded) {
              final invoices = state.invoices;
              final filteredInvoices = _filterInvoices(invoices);
              final stats = _calculateStats(invoices);
        
              // Live customer-name lookup; rebuilds whenever accounts change.
              final accountsState = context.watch<AccountsCubit>().state;
              final customerNames = accountsState is AccountsLoaded
                  ? {
                      for (final account in accountsState.accounts)
                        if (account.id != null) account.id!: account.name,
                    }
                  : const <int, String>{};
        
              return RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onRefresh: () async {
                  await context.read<SalesCubit>().loadInvoices().timeout(
                    const Duration(seconds: 6),
                    onTimeout: () {},
                  );
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: BillsHeader(
                        searchQuery: _searchQuery,
                        onSearchChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        onFilterPressed: _toggleFilterOpen,
                        onNewBillPressed: () {
                          context.pushNamed(AppRoutes.salesAddInvoice);
                        },
                        isFilterOpen: _filterOpen,
                      ),
                    ),
        
                    // Filter Panel
                    if (_filterOpen)
                      SliverToBoxAdapter(
                        child: FilterPanel(
                          sortBy: _sortBy,
                          onSortChanged: (sort) {
                            setState(() {
                              _sortBy = sort;
                            });
                          },
                        ),
                      ),
        
                    // Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppConstant.defaultPadding,
                        child: StatsCards(stats: stats),
                      ),
                    ),
        
                    // Bills List
                    if (filteredInvoices.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyBillsView(
                          isSearching: _searchQuery.isNotEmpty,
                          onCreateInvoice: () =>
                              context.pushNamed(AppRoutes.salesAddInvoice),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final invoice = filteredInvoices[index];
                            return BillCard(
                              invoice: invoice,
                              customerName:
                                  customerNames[invoice.customerId] ??
                                  'عميل #${invoice.customerId}',
                              onDelete: () {
                                _showDeleteDialog(context, invoice);
                              },
                            );
                          }, childCount: filteredInvoices.length),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<InvoiceEntity> _filterInvoices(List<InvoiceEntity> invoices) {
    var filtered = invoices.where((inv) => inv.invoiceType == 1).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (inv) =>
                inv.number.contains(_searchQuery) ||
                (inv.id.toString() == _searchQuery),
          )
          .toList();
    }

    final sort =
        InvoiceSortOption.tryFromCode(_sortBy) ?? InvoiceSortOption.dateDesc;
    filtered.sort((a, b) {
      return switch (sort) {
        InvoiceSortOption.dateDesc => b.date.compareTo(a.date),
        InvoiceSortOption.dateAsc => a.date.compareTo(b.date),
        InvoiceSortOption.totalDesc => (b.totalAmount ?? 0).compareTo(
          a.totalAmount ?? 0,
        ),
        InvoiceSortOption.totalAsc => (a.totalAmount ?? 0).compareTo(
          b.totalAmount ?? 0,
        ),
      };
    });

    return filtered;
  }

  BillStats _calculateStats(List<InvoiceEntity> invoices) {
    final total = invoices.length;
    final totalAmount = invoices.fold(
      0.0,
      (sum, inv) => sum + (inv.totalAmount ?? 0),
    );
    final paidInvoices = invoices
        .where(
          (inv) =>
              InvoicePaymentStatus.tryFromValue(inv.paymentStatus) ==
              InvoicePaymentStatus.paid,
        )
        .toList();
    final paidAmount = paidInvoices.fold(
      0.0,
      (sum, inv) => sum + (inv.totalAmount ?? 0),
    );

    return BillStats(
      total: total,
      paid: paidInvoices.length,
      partial: 0,
      unpaid: total - paidInvoices.length,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: totalAmount - paidAmount,
    );
  }

  void _showDeleteDialog(BuildContext context, InvoiceEntity invoice) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (invoice.id != null) {
                context.read<SalesCubit>().removeInvoice(invoice.id!);
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// States: loading / empty
// ═══════════════════════════════════════════════
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'جارِ تحميل الفواتير...',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBillsView extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreateInvoice;

  const _EmptyBillsView({
    required this.isSearching,
    required this.onCreateInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.35)
                  : AppColors.saudiMint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 34,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'لا توجد نتائج مطابقة' : 'لا توجد فواتير بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'جرّب البحث برقم مختلف'
                : 'ابدأ بإنشاء أول فاتورة مبيعات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 20),
            PressableScale(
              onTap: onCreateInvoice,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl28),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'فاتورة جديدة',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Header: title + new invoice + search + filter toggle
// ═══════════════════════════════════════════════
class BillsHeader extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onNewBillPressed;
  final bool isFilterOpen;

  const BillsHeader({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onNewBillPressed,
    required this.isFilterOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'فواتير المبيعات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HasibButton(
                  label: 'فاتورة جديدة',
                  onPressed: onNewBillPressed,
                  leading: const Icon(Icons.add, size: 20),
                  variant: HasibButtonVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    hint: 'ابحث برقم الفاتورة...',
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      hintText: 'ابحث برقم الفاتورة...',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  onTap: onFilterPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isFilterOpen
                          ? (isDark
                                ? AppColors.primaryLight.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.08))
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.slate50),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isFilterOpen
                            ? AppColors.primary.withValues(
                                alpha: isDark ? 0.5 : 0.35,
                              )
                            : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: isFilterOpen
                              ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'فلتر',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFilterOpen
                                ? (isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Sort panel (Material 3 themed dropdown)
// ═══════════════════════════════════════════════
class FilterPanel extends StatelessWidget {
  final String sortBy;
  final Function(String) onSortChanged;

  const FilterPanel({
    super.key,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: AppConstant.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sort_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'الترتيب حسب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: sortBy,
            isExpanded: true,
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: const [
              DropdownMenuItem(
                value: 'date-desc',
                child: Text('التاريخ (الأحدث أولاً)'),
              ),
              DropdownMenuItem(
                value: 'date-asc',
                child: Text('التاريخ (الأقدم أولاً)'),
              ),
              DropdownMenuItem(
                value: 'total-desc',
                child: Text('المبلغ (الأعلى أولاً)'),
              ),
              DropdownMenuItem(
                value: 'total-asc',
                child: Text('المبلغ (الأقل أولاً)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) onSortChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Stats strip
// ═══════════════════════════════════════════════
class StatsCards extends StatelessWidget {
  final BillStats stats;

  const StatsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'إجمالي الفواتير',
            value: '${stats.total}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'إجمالي المبلغ',
            value: '${stats.totalAmount.toStringAsFixed(0)} ر.س',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Bill card: status chip + customer + amount + delete
// ═══════════════════════════════════════════════
class BillCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final String customerName;
  final VoidCallback onDelete;

  const BillCard({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.onDelete,
  });

  Color _statusColor(bool isDark) {
    final status = InvoicePaymentStatus.tryFromValue(invoice.paymentStatus);
    return switch (status) {
      InvoicePaymentStatus.paid =>
        isDark ? AppColors.success : AppColors.primary,
      InvoicePaymentStatus.partial => AppColors.warning,
      _ => isDark ? AppColors.errorLight : AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000));
    final status = InvoicePaymentStatus.tryFromValue(invoice.paymentStatus);
    final statusColor = _statusColor(isDark);

    return PressableScale(
      pressedScale: 0.985,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                        : AppColors.saudiMint,
                    borderRadius: BorderRadius.circular(AppRadius.sm10),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    size: 19,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    invoice.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.xl28),
                    ),
                    child: Text(
                      status.labelAr,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                _CardActionMenu(onDelete: onDelete),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    '${invoice.totalAmount?.toStringAsFixed(2) ?? 0} ر.س',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionMenu extends StatelessWidget {
  final VoidCallback onDelete;

  const _CardActionMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
    );
  }
}
