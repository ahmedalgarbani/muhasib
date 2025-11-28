import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';

class ImprovedStep1Customer extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;

  const ImprovedStep1Customer({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdate,
    required this.onNext,
  }) : super(key: key);

  @override
  State<ImprovedStep1Customer> createState() => _ImprovedStep1CustomerState();
}

class _ImprovedStep1CustomerState extends State<ImprovedStep1Customer> {
  late TextEditingController _notesController;
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  bool _showCustomersList = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes);
    
    // Load customers and warehouses
    context.read<CustomersCubit>().loadCustomers();
    context.read<WarehousesCubit>().loadWarehouses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query, List<Customer> customers) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = customers;
      } else {
        _filteredCustomers = customers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                (customer.phone?.contains(query) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Selection Section
          const Text(
            'العميل *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          
          // Customer Input with Add Button
          Row(
            children: [
              Expanded(
                child: BlocBuilder<CustomersCubit, CustomersState>(
                  builder: (context, state) {
                    if (state is CustomersLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (state is CustomersLoaded) {
                      final customers = state.customers
                          .where((c) => c.type == 1 || c.type == 2) // Only customers, not suppliers
                          .toList();
                      
                      return Column(
                        children: [
                          // Selected Customer or Search Field
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showCustomersList = !_showCustomersList;
                                _filteredCustomers = customers;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: widget.invoice.customer != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: widget.invoice.customer != null
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: widget.invoice.customer != null
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.invoice.customer!.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (widget.invoice.customer!.phone != null)
                                                Text(
                                                  widget.invoice.customer!.phone!,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              Text(
                                                'الرصيد: ${NumberFormatter.formatCurrency(widget.invoice.customer!.balance)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: widget.invoice.customer!.balance > 0
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'اختر عميل من القائمة',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                  ),
                                  Icon(
                                    _showCustomersList
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Customers List Dropdown
                          if (_showCustomersList) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Search Field
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'ابحث عن عميل...',
                                        prefixIcon: Icon(Icons.search, size: 20),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => _filterCustomers(value, customers),
                                    ),
                                  ),
                                  // Customers List
                                  Expanded(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredCustomers.isEmpty
                                          ? customers.length
                                          : _filteredCustomers.length,
                                      itemBuilder: (context, index) {
                                        final customer = _filteredCustomers.isEmpty
                                            ? customers[index]
                                            : _filteredCustomers[index];
                                        
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFFEFF6FF),
                                            child: Text(
                                              customer.name.substring(0, 1),
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            customer.name,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (customer.phone != null)
                                                Text(
                                                  customer.phone!,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'الرصيد: ${NumberFormatter.formatCurrency(customer.balance)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: customer.balance > 0
                                                          ? Colors.red
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  if (customer.creditLimit > 0) ...[
                                                    const Text(' | ', style: TextStyle(fontSize: 11)),
                                                    Text(
                                                      'الحد: ${NumberFormatter.formatCurrency(customer.creditLimit)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF6B7280),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            widget.onInvoiceUpdate(
                                              widget.invoice.copyWith(customer: customer),
                                            );
                                            setState(() {
                                              _showCustomersList = false;
                                              _searchController.clear();
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    
                    if (state is CustomersError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    
                    return const SizedBox();
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Add Customer Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
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
                    
                    if (newCustomer != null && mounted) {
                      widget.onInvoiceUpdate(
                        widget.invoice.copyWith(customer: newCustomer),
                      );
                      
                      // Reload customers list
                      context.read<CustomersCubit>().loadCustomers();
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'إضافة عميل جديد',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Date and Currency Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التاريخ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDate(widget.invoice.date),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'العملة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.invoice.currency,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Warehouse Selection
          BlocBuilder<WarehousesCubit, WarehousesState>(
            builder: (context, state) {
              if (state is WarehousesLoaded && state.warehouses.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المخزن',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: widget.invoice.warehouse,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.warehouse, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: state.warehouses.map((warehouse) {
                        return DropdownMenuItem(
                          value: warehouse.name,
                          child: Text(
                            warehouse.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onInvoiceUpdate(
                            widget.invoice.copyWith(warehouse: value),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          
          // Notes Section
          ExpandableSection(
            title: 'معلومات إضافية',
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف ملاحظات...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  widget.onInvoiceUpdate(
                    widget.invoice.copyWith(notes: value),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.invoice.customer != null ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'التالي: إضافة الأصناف',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
