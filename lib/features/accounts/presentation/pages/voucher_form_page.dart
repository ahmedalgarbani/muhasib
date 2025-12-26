import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';

import '../cubit/vouchers_cubit.dart';

class VoucherFormPage extends StatefulWidget {
  final VoucherEntity? voucher;
  final VoucherType defaultType;

  const VoucherFormPage({
    super.key,
    this.voucher,
    required this.defaultType,
  });

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy/MM/dd');

  late VoucherType _type;
  late DateTime _date;
  late TextEditingController _numberController;
  late TextEditingController _statementController;
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  int? _accountId;
  String? _accountName;
  final List<_VoucherLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    final voucher = widget.voucher;
    _type = voucher?.type ?? widget.defaultType;
    _date = voucher?.date ?? DateTime.now();
    _numberController = TextEditingController(
      text: voucher?.number.toString() ?? '',
    );
    _statementController = TextEditingController(text: voucher?.statement ?? '');
    _amountController = TextEditingController(
      text: voucher != null ? voucher.amount.toStringAsFixed(2) : '',
    );
    _referenceController = TextEditingController(
      text: voucher?.referenceNumber ?? '',
    );
    _accountId = voucher?.accountId;
    _accountName = voucher?.accountName;

    if (voucher != null && voucher.lines.isNotEmpty) {
      for (final line in voucher.lines) {
        _lines.add(
          _VoucherLineInput(
            accountId: line.accountId,
            accountName: line.accountName,
            amount: line.amount,
            statement: line.statement,
          ),
        );
      }
    }

    if (voucher == null) {
      context.read<VouchersCubit>().refreshNumber(_type);
    }

    final accountsCubit = context.read<AccountsCubit>();
    if (accountsCubit.allAccounts == null) {
      accountsCubit.loadAllAccounts();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _statementController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocListener<VouchersCubit, VouchersState>(
        listener: (context, state) {
          if (state is VoucherActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop(true);
          } else if (state is VouchersFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is VoucherNumberGenerated &&
              widget.voucher == null &&
              state.type == _type) {
            _numberController.text = state.number.toString();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.voucher == null ? 'إضافة سند' : 'تعديل سند'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 12),
                    _buildHeaderFields(accounts),
                    const SizedBox(height: 12),
                    _buildLinesSection(accounts),
                    const SizedBox(height: 24),
                    BlocBuilder<VouchersCubit, VouchersState>(
                      builder: (context, state) {
                        final saving = state is VoucherActionInProgress;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              saving ? 'جارٍ الحفظ...' : 'حفظ السند',
                            ),
                            onPressed: saving ? null : _onSave,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('سند قبض'),
          selected: _type == VoucherType.receipt,
          onSelected: (_) {
            setState(() => _type = VoucherType.receipt);
            if (widget.voucher == null) {
              context.read<VouchersCubit>().refreshNumber(_type);
            }
          },
        ),
        ChoiceChip(
          label: const Text('سند صرف'),
          selected: _type == VoucherType.payment,
          onSelected: (_) {
            setState(() => _type = VoucherType.payment);
            if (widget.voucher == null) {
              context.read<VouchersCubit>().refreshNumber(_type);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeaderFields(List<AccountEntity> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم السند',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'مطلوب';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dateFormat.format(_date)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _accountId,
          decoration: const InputDecoration(
            labelText: 'الحساب الرئيسي',
            border: OutlineInputBorder(),
          ),
          items: accounts
              .map(
                (a) => DropdownMenuItem<int>(
                  value: a.id,
                  child: Text('${a.code} - ${a.name}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _accountId = value;
              _accountName = _findAccountName(value, accounts);
            });
          },
          validator: (value) =>
              value == null ? 'اختيار الحساب مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final parsed = double.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'الرجاء إدخال مبلغ صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _statementController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'البيان',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'البيان مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _referenceController,
          decoration: const InputDecoration(
            labelText: 'المرجع (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLinesSection(List<AccountEntity> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تفاصيل السطور (اختياري)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(
                () => _lines.add(_VoucherLineInput()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة سطر'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_lines.isEmpty)
          const Text(
            'في حال عدم إضافة سطور سيتم حفظ السند على المبلغ الرئيسي فقط.',
            style: TextStyle(color: Colors.grey),
          ),
        ..._lines.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final line = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: line.accountId,
                      decoration: const InputDecoration(
                        labelText: 'الحساب',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text('${a.code} - ${a.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          line.accountId = value;
                          line.accountName = _findAccountName(value, accounts);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: line.amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: line.statementController,
                      decoration: const InputDecoration(
                        labelText: 'بيان السطر',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _lines.removeAt(index).dispose();
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف السطر',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  String? _findAccountName(int? accountId, List<AccountEntity> accounts) {
    if (accountId == null) return null;
    for (final account in accounts) {
      if (account.id == accountId) {
        return account.name;
      }
    }
    return null;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار الحساب الرئيسي')),
      );
      return;
    }

    final headerAmount = double.tryParse(_amountController.text) ?? 0;
    final filteredLines = _lines
        .map((line) => line.toEntity(_statementController.text))
        .where((line) => (line.amount ?? 0) > 0 && line.accountId != null)
        .toList();

    final totalLines = filteredLines.fold<double>(
      0,
      (sum, line) => sum + (line.amount ?? 0),
    );

    final voucher = VoucherEntity(
      id: widget.voucher?.id,
      number: int.tryParse(_numberController.text) ?? 0,
      date: _date,
      statement: _statementController.text.trim(),
      amount: filteredLines.isNotEmpty ? totalLines : headerAmount,
      accountId: _accountId!,
      accountName: _accountName,
      type: _type,
      referenceNumber: _referenceController.text.trim(),
      localAmount: null,
      currencyCode: null,
      currencyId: null,
      exchangeRate: null,
      imagePath: widget.voucher?.imagePath,
      parentNumber: widget.voucher?.parentNumber,
      parentId: widget.voucher?.parentId,
      status: widget.voucher?.status ?? 0,
      lines: filteredLines,
    );

    await context.read<VouchersCubit>().saveVoucher(voucher);
  }
}

class _VoucherLineInput {
  _VoucherLineInput({
    this.accountId,
    this.accountName,
    double? amount,
    String? statement,
  })  : amountController = TextEditingController(
          text: amount != null ? amount.toString() : '',
        ),
        statementController = TextEditingController(text: statement ?? '');

  int? accountId;
  String? accountName;
  final TextEditingController amountController;
  final TextEditingController statementController;

  VoucherLineEntity toEntity(String fallbackStatement) {
    final parsedAmount = double.tryParse(amountController.text) ?? 0;
    final lineStatement =
        statementController.text.trim().isEmpty
            ? fallbackStatement
            : statementController.text.trim();

    return VoucherLineEntity(
      accountId: accountId,
      accountName: accountName,
      amount: parsedAmount,
      statement: lineStatement,
    );
  }

  void dispose() {
    amountController.dispose();
    statementController.dispose();
  }
}

