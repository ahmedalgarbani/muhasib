import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class Step1Customer extends StatefulWidget {
  final Invoice invoice;
  final List<Customer> customers;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onShowCustomerSheet;

  const Step1Customer({
    super.key,
    required this.invoice,
    required this.customers,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onShowCustomerSheet,
  });

  @override
  State<Step1Customer> createState() => _Step1CustomerState();
}

class _Step1CustomerState extends State<Step1Customer> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = widget.invoice.customer != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Selection Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'العميل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () async {
                          final cubit = getIt<CustomersCubit>();
                          final newCustomer = await showDialog<Customer>(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: cubit,
                              child: const AddCustomerDialog(partyType: 1),
                            ),
                          );

                          if (newCustomer != null && mounted) {
                            widget.onInvoiceUpdate(
                              widget.invoice.copyWith(customer: newCustomer),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: widget.onShowCustomerSheet,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasCustomer
                                      ? widget.invoice.customer!.name
                                      : 'اختر العميل',
                                  style: TextStyle(
                                    fontWeight: hasCustomer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: hasCustomer
                                        ? AppColors.grey900
                                        : AppColors.grey600,
                                  ),
                                ),
                                if (hasCustomer &&
                                    widget.invoice.customer!.phone != null)
                                  Text(
                                    widget.invoice.customer!.phone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  if (hasCustomer) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرصيد الحالي:'),
                          Text(
                            NumberFormatter.formatCurrency(
                              widget.invoice.customer!.balance,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.invoice.customer!.balance > 0
                                  ? Colors.red
                                  : Colors.green,
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
          const SizedBox(height: AppSpacing.md),

          // Invoice Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل الفاتورة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رقم الفاتورة',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.invoice.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'التاريخ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              DateFormatter.formatDate(widget.invoice.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Additional Notes Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملاحظات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextInputField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'أضف ملاحظات...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onChanged: (value) {
                      widget.onInvoiceUpdate(
                        widget.invoice.copyWith(notes: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          HasibButton(
            label: 'التالي: إضافة الأصناف',
            onPressed: widget.invoice.customer != null ? widget.onNext : null,
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
