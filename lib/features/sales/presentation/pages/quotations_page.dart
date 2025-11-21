import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/presentation/widgets/constants/invoice_ui_constants.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/sales_invoice_screen.dart';

class QuotationsPage extends StatefulWidget {
  const QuotationsPage({Key? key}) : super(key: key);

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOnlyOpen = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  void _loadQuotations() {
    if (_showOnlyOpen) {
      context.read<SalesCubit>().loadOpenQuotations();
    } else {
      context.read<SalesCubit>().loadQuotations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      endDrawer: const MainAppDrawer(),
      appBar: CustomAppBar(
        onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: BlocConsumer<SalesCubit, SalesState>(
              listener: (context, state) {
                if (state is SalesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is QuotationConverted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحويل عرض السعر إلى فاتورة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadQuotations();
                }
              },
              builder: (context, state) {
                if (state is SalesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is QuotationsLoaded) {
                  if (state.quotations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildQuotationsList(state.quotations);
                } else {
                  return const Center(child: Text('ابدأ بتحميل عروض الأسعار'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalesInvoiceScreen(
                invoiceType: InvoiceType.quotation,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('عرض سعر جديد'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث برقم العرض أو اسم العميل...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
              onChanged: (value) {
                // Implement search logic
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _loadQuotations,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'الفلتر:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('مفتوحة فقط'),
            selected: _showOnlyOpen,
            onSelected: (value) {
              setState(() {
                _showOnlyOpen = value;
                _loadQuotations();
              });
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: const Color(0xFFDBEAFE),
            checkmarkColor: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('الكل'),
            selected: !_showOnlyOpen,
            onSelected: (value) {
              setState(() {
                _showOnlyOpen = !value;
                _loadQuotations();
              });
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: const Color(0xFFDBEAFE),
            checkmarkColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsList(List<InvoiceEntity> quotations) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadQuotations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quotations.length,
        itemBuilder: (context, index) {
          return _buildQuotationCard(quotations[index]);
        },
      ),
    );
  }

  Widget _buildQuotationCard(InvoiceEntity quotation) {
    final isConverted = quotation.nextInvoiceId != null && quotation.nextInvoiceId! > 0;
    final status = isConverted ? InvoiceStatus.converted : InvoiceStatus.open;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to quotation detail
          // Navigator.pushNamed(context, '/quotations/detail', arguments: quotation.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              InvoiceTypeUI.getIcon(InvoiceType.quotation),
                              size: 20,
                              color: InvoiceTypeUI.getColor(InvoiceType.quotation),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              quotation.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(quotation.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InvoiceStatusBadge(status: status, showIcon: true),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'عميل #${quotation.customerId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
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
                        'الإجمالي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(quotation.finalAmt ?? quotation.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  if (!isConverted)
                    ElevatedButton.icon(
                      onPressed: () {
                        _showConvertDialog(quotation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.transform, size: 18),
                      label: const Text('تحويل لفاتورة'),
                    ),
                ],
              ),
              if (isConverted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تم التحويل إلى فاتورة: ${quotation.nextInvoiceNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B21A8),
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عروض أسعار',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء عرض سعر جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showConvertDialog(InvoiceEntity quotation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحويل عرض السعر'),
        content: Text(
          'هل تريد تحويل عرض السعر ${quotation.number} إلى فاتورة مبيعات؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Create sales invoice from quotation
              final salesInvoice = quotation.copyWith(
                invoiceType: InvoiceType.salesInvoice.value,
                number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                parentInvoiceId: quotation.id,
                parentInvoiceNumber: quotation.number,
              );
              context.read<SalesCubit>().convertQuotation(
                    quotation.id!,
                    salesInvoice,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('تحويل'),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd', 'ar').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ريال';
  }
}

// Extension to add copyWith to InvoiceEntity
extension InvoiceEntityExtension on InvoiceEntity {
  InvoiceEntity copyWith({
    int? id,
    int? invoiceType,
    String? number,
    int? date,
    String? statement,
    double? amount,
    double? finalAmt,
    int? customerId,
    int? stockId,
    int? invoiceTransType,
    int? parentInvoiceId,
    String? parentInvoiceNumber,
    List<InvoiceLineEntity>? lines,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceType: invoiceType ?? this.invoiceType,
      number: number ?? this.number,
      date: date ?? this.date,
      statement: statement ?? this.statement,
      amount: amount ?? this.amount,
      totalAmount: totalAmount,
      taxAmt: taxAmt,
      taxRatio: taxRatio,
      discountAmt: discountAmt,
      discountRatio: discountRatio,
      otherFeeAmt: otherFeeAmt,
      otherFeeNetRatio: otherFeeNetRatio,
      netRevenueAmt: netRevenueAmt,
      totalAmountAfterDiscount: totalAmountAfterDiscount,
      finalAmt: finalAmt ?? this.finalAmt,
      currencyId: currencyId,
      stockId: stockId ?? this.stockId,
      customerId: customerId ?? this.customerId,
      taxId: taxId,
      otherFeeAccountId: otherFeeAccountId,
      invoiceTransType: invoiceTransType ?? this.invoiceTransType,
      parentInvoiceId: parentInvoiceId ?? this.parentInvoiceId,
      parentInvoiceNumber: parentInvoiceNumber ?? this.parentInvoiceNumber,
      nextInvoiceType: nextInvoiceType,
      nextInvoiceId: nextInvoiceId,
      nextInvoiceNumber: nextInvoiceNumber,
      uNo: uNo,
      currencyCode: currencyCode,
      exchangeRate: exchangeRate,
      imagePath: imagePath,
      paymentStatus: paymentStatus,
      shippingAddress: shippingAddress,
      dueDate: dueDate,
      lines: lines ?? this.lines,
    );
  }
}
