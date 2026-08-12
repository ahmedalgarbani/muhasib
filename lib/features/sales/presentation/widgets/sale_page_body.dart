import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/models/bill_models.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

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
    context.read<AccountsCubit>().loadAllAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return const SalesBillsScreen();
  }
}

class SalesBillsScreen extends StatefulWidget {
  const SalesBillsScreen({Key? key}) : super(key: key);

  @override
  State<SalesBillsScreen> createState() => _SalesBillsScreenState();
}

class _SalesBillsScreenState extends State<SalesBillsScreen> {
  String _searchQuery = "";
  bool _filterOpen = false;
  String _sortBy = "date-desc";
  // Local filter state
  // int? _selectedPaymentStatus; // 0: unpaid, 1: paid, etc. (Mapping needed)

  void _toggleFilterOpen() {
    setState(() {
      _filterOpen = !_filterOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocBuilder<SalesCubit, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SalesError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is SalesLoaded) {
            final invoices = state.invoices;
            final filteredInvoices = _filterInvoices(invoices);
            final stats = _calculateStats(invoices);

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: BillsHeader(
                    searchQuery: _searchQuery,
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                      // Optionally trigger backend search
                      // context.read<SalesCubit>().search(query);
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
                    padding: const EdgeInsets.all(16),
                    child: StatsCards(stats: stats),
                  ),
                ),

                // Bills List
                if (filteredInvoices.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📄', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد فواتير',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
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
                          onTap: () {},
                          onView: () {},
                          onEdit: () {},
                          onDownload: () {},
                          onShare: () {},
                          onDelete: () {
                            _showDeleteDialog(context, invoice);
                          },
                        );
                      }, childCount: filteredInvoices.length),
                    ),
                  ),
              ],
            );
          }
          return const Center(child: Text('No Data'));
        },
      ),
    );
  }

  List<InvoiceEntity> _filterInvoices(List<InvoiceEntity> invoices) {
    // This page is "Sales List" -> only show sales invoices
    var filtered = invoices
        .where((inv) => inv.invoiceType == 1)
        .toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (inv) =>
                inv.number.contains(_searchQuery) ||
                (inv.id.toString() == _searchQuery),
          )
          .toList();
    }

    // Sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case "date-desc":
          return b.date.compareTo(a.date);
        case "date-asc":
          return a.date.compareTo(b.date);
        case "total-desc":
          return (b.totalAmount ?? 0).compareTo(a.totalAmount ?? 0);
        case "total-asc":
          return (a.totalAmount ?? 0).compareTo(b.totalAmount ?? 0);
        default:
          return 0;
      }
    });

    return filtered;
  }

  BillStats _calculateStats(List<InvoiceEntity> invoices) {
    final total = invoices.length;
    final totalAmount = invoices.fold(
      0.0,
      (sum, inv) => sum + (inv.totalAmount ?? 0),
    );
    // Assuming paymentStatus 1 is paid, 0 is unpaid for now
    final paidInvoices = invoices
        .where((inv) => inv.paymentStatus == 1)
        .toList();
    final paidAmount = paidInvoices.fold(
      0.0,
      (sum, inv) => sum + (inv.totalAmount ?? 0),
    );

    return BillStats(
      total: total,
      paid: paidInvoices.length,
      partial: 0, // Not supported yet
      unpaid: total - paidInvoices.length,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: totalAmount - paidAmount,
    );
  }

  void _showDeleteDialog(BuildContext context, InvoiceEntity invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

class BillsHeader extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onNewBillPressed;
  final bool isFilterOpen;

  const BillsHeader({
    Key? key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onNewBillPressed,
    required this.isFilterOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'فواتير المبيعات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onNewBillPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('فاتورة جديدة'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الفاتورة...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onFilterPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFilterOpen
                        ? AppColors.blue50
                        : Colors.white,
                  ),
                  icon: const Icon(Icons.filter_list, size: 20),
                  label: const Text('فلتر'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FilterPanel extends StatelessWidget {
  final String sortBy;
  final Function(String) onSortChanged;

  const FilterPanel({
    Key? key,
    required this.sortBy,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الترتيب حسب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: sortBy,
            isExpanded: true,
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

class StatsCards extends StatelessWidget {
  final BillStats stats;

  const StatsCards({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('إجمالي الفواتير', '${stats.total}', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            'إجمالي المبلغ',
            '${stats.totalAmount.toStringAsFixed(0)} ر.س',
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BillCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const BillCard({
    Key? key,
    required this.invoice,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Invoices store date as seconds since epoch
    final dateStr = DateFormat('yyyy-MM-dd').format(
      DateTime.fromMillisecondsSinceEpoch(invoice.date * 1000),
    );
    // Try to find customer name from AccountsCubit
    final accountsState = context.read<AccountsCubit>().state;
    String customerName = 'Customer #${invoice.customerId}';
    if (accountsState is AccountsLoaded) {
      // If found, use name. But firstWhere throws if not found unless orElse is provided.
      // Let's use try/catch or collection firstWhereOrNull if available, or just loop.
      try {
        final customer = accountsState.accounts.firstWhere(
          (a) => a.id == invoice.customerId,
        );
        customerName = customer.name;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoice.number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            Text(customerName, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${invoice.totalAmount?.toStringAsFixed(2) ?? 0} ر.س',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(dateStr, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
