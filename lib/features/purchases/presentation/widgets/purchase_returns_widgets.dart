import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseReturnsHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onRefresh;
  final ValueChanged<String>? onSearchChanged;

  const PurchaseReturnsHeaderWidget({
    super.key,
    required this.searchController,
    required this.onRefresh,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: AppConstant.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.assignment_return,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مردودات المشتريات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إدارة المردودات والمرتجعات',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextInputField(
            controller: searchController,
            hint: 'البحث في المردودات...',
            decoration: InputDecoration(
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (value) {
              onSearchChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }
}

class PurchaseReturnsTabBarWidget extends StatelessWidget {
  final TabController controller;

  const PurchaseReturnsTabBarWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        labelColor: Colors.red,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.red,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.list_alt, size: 20), text: 'قائمة المردودات'),
          Tab(icon: Icon(Icons.analytics, size: 20), text: 'الإحصائيات'),
        ],
      ),
    );
  }
}

class PurchaseReturnsListWidget extends StatelessWidget {
  final List<InvoiceEntity> returns;
  final VoidCallback onRefresh;

  const PurchaseReturnsListWidget({
    super.key,
    required this.returns,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: AppConstant.defaultPadding,
        itemCount: returns.length,
        itemBuilder: (context, index) {
          return PurchaseReturnCardWidget(returnInvoice: returns[index]);
        },
      ),
    );
  }
}

class PurchaseReturnCardWidget extends StatelessWidget {
  final InvoiceEntity returnInvoice;

  const PurchaseReturnCardWidget({
    super.key,
    required this.returnInvoice,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormatter.formatDate(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormatter.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.red.shade100),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm6),
                          ),
                          child: const Icon(
                            Icons.assignment_return,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مردود #${returnInvoice.number}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(returnInvoice.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Text(
                      'مردود',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              if (returnInvoice.parentInvoiceNumber != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'مرتبط بالفاتورة #${returnInvoice.parentInvoiceNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'المورد #${returnInvoice.customerId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${returnInvoice.lines.length} منتج',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قيمة المردود',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(
                          returnInvoice.finalAmt ?? returnInvoice.amount,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility, size: 18),
                        color: Colors.blue,
                        tooltip: 'عرض التفاصيل',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.print, size: 18),
                        color: Colors.green,
                        tooltip: 'طباعة',
                      ),
                    ],
                  ),
                ],
              ),
              if (returnInvoice.statement != null &&
                  returnInvoice.statement!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppRadius.sm6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          returnInvoice.statement!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PurchaseReturnsStatisticsTabWidget extends StatelessWidget {
  final List<InvoiceEntity>? returns;

  const PurchaseReturnsStatisticsTabWidget({super.key, this.returns});

  @override
  Widget build(BuildContext context) {
    final list = returns ?? const <InvoiceEntity>[];
    final totalCount = list.length;
    final totalValue = list.fold<double>(0, (s, e) => s + (e.finalAmt ?? e.amount));
    final avgValue = totalCount > 0 ? totalValue / totalCount : 0.0;
    final now = DateTime.now();
    final thisMonthCount = list.where((e) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.date * 1000);
      return d.year == now.year && d.month == now.month;
    }).length;
    String fmt(double v) => NumberFormatter.formatCurrency(v);
    return SingleChildScrollView(
      padding: AppConstant.defaultPadding,
      child: Column(
        children: [
          PurchaseReturnStatCardWidget(
            title: 'إجمالي المردودات',
            value: '$totalCount',
            icon: Icons.assignment_return,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          PurchaseReturnStatCardWidget(
            title: 'قيمة المردودات',
            value: fmt(totalValue),
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          PurchaseReturnStatCardWidget(
            title: 'متوسط قيمة المردود',
            value: fmt(avgValue),
            icon: Icons.analytics,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          PurchaseReturnStatCardWidget(
            title: 'المردودات هذا الشهر',
            value: '$thisMonthCount',
            icon: Icons.calendar_month,
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          CustomCardContainer(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: AppConstant.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أسباب المردودات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 16),
                  PurchaseReturnReasonRowWidget(
                    reason: 'عيوب في المنتج',
                    percentage: 45,
                    color: Colors.red,
                  ),
                  SizedBox(height: 12),
                  PurchaseReturnReasonRowWidget(
                    reason: 'عدم مطابقة المواصفات',
                    percentage: 30,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 12),
                  PurchaseReturnReasonRowWidget(
                    reason: 'تأخر في التسليم',
                    percentage: 15,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  PurchaseReturnReasonRowWidget(
                    reason: 'أخرى',
                    percentage: 10,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PurchaseReturnStatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const PurchaseReturnStatCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseReturnReasonRowWidget extends StatelessWidget {
  final String reason;
  final int percentage;
  final Color color;

  const PurchaseReturnReasonRowWidget({
    super.key,
    required this.reason,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(reason, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          flex: 5,
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
