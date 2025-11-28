import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';

class Step1Customer extends StatefulWidget {
  final Invoice invoice;
  final List<Customer> customers;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onShowCustomerSheet;

  const Step1Customer({
    Key? key,
    required this.invoice,
    required this.customers,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onShowCustomerSheet,
  }) : super(key: key);

  @override
  State<Step1Customer> createState() => _Step1CustomerState();
}

class _Step1CustomerState extends State<Step1Customer> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('�?�?�?�?�?�? *', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onShowCustomerSheet,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: widget.invoice.customer != null
                            ? AppColors.primary
                            : AppColors.grey300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.invoice.customer != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.invoice.customer!.name,
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '�?�?�?���?�?: ${NumberFormatter.formatCurrency(widget.invoice.customer!.balance)} | �?�?�?�?: ${NumberFormatter.formatCurrency(widget.invoice.customer!.creditLimit)}',
                                style: AppTextStyles.small,
                              ),
                            ],
                          )
                        : Text(
                            '�?�?�?�? �?�?�?�?�?�?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () async {
                    final newCustomer = await showDialog<Customer>(
                      context: context,
                      builder: (context) => BlocProvider(
                        create: (_) => getIt<CustomersCubit>(),
                        child: const AddCustomerDialog(),
                      ),
                    );

                    if (newCustomer != null) {
                      // Update the invoice with the new customer
                      widget.onInvoiceUpdate(
                        widget.invoice.copyWith(customer: newCustomer),
                      );

                      // Add the new customer to the customers list if needed
                      if (!widget.customers.any(
                        (c) => c.id == newCustomer.id,
                      )) {
                        widget.customers.add(newCustomer);
                      }
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  tooltip: 'إضافة عميل جديد',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('�?�?�?�?�?�?�?', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: widget.invoice.date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          widget.onInvoiceUpdate(
                            widget.invoice.copyWith(date: date),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${widget.invoice.date.year}-${widget.invoice.date.month.toString().padLeft(2, '0')}-${widget.invoice.date.day.toString().padLeft(2, '0')}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('�?�?�?�?�?�?', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        border: Border.all(color: AppColors.grey200, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.invoice.currency,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ExpandableSection(
            title: '�?�?�?�?�?�? �?�?�?�?�?�?',
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('�?�?�?�?�?�?�?', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      border: Border.all(color: AppColors.grey200, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.invoice.notes,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.grey400,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '�?�?�?�?�?�? �?�?�?�?: �?�?�?�?�?�?�?�?',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '�?�?�?�?�?�?�?�? �?�?�?�?�?�?�?�?',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: widget.invoice.warehouse,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '�?�?�?�?�?�?�? ���?�?�?�?',
                        child: Text('�?�?�?�?�?�?�? ���?�?�?�?'),
                      ),
                      DropdownMenuItem(
                        value: '�?�?�?�?�?�?�? ���?�?�?�? 2',
                        child: Text('�?�?�?�?�?�?�? ���?�?�?�? 2'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onInvoiceUpdate(
                          widget.invoice.copyWith(warehouse: value),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('�?�?�?�?�?�?�?', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '��?�? �?�?�?�?�?�?�?...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
          PrimaryButton(
            text: '�?�?�?�?�?�?: �?�?�?�?�? �?�?����?�?�?',
            onPressed: widget.invoice.customer != null ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}
