import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/opening_balance_cubit.dart';

class OpeningBalanceApp extends StatelessWidget {
  const OpeningBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OpeningBalanceCubit>()..initializeForm(),
      child: const OpeningBalancePage(),
    );
  }
}

class OpeningBalancePage extends StatefulWidget {
  const OpeningBalancePage({super.key});

  @override
  State<OpeningBalancePage> createState() => _OpeningBalancePageState();
}

class _OpeningBalancePageState extends State<OpeningBalancePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OpeningBalanceCubit, OpeningBalanceState>(
      listener: (context, state) {
        if (state is OpeningBalanceError) {
          _showSnack(state.message, isError: true);
        } else if (state is OpeningBalanceSaved) {
          _showSnack('Opening balance saved');
          context.read<OpeningBalanceCubit>().initializeForm();
        } else if (state is OpeningBalancePosted) {
          _showSnack('Opening balance posted');
        } else if (state is OpeningBalanceDeleted) {
          _showSnack('Opening balance deleted');
          context.read<OpeningBalanceCubit>().initializeForm();
        }
      },
      builder: (context, state) {
        final cubit = context.read<OpeningBalanceCubit>();
        final opening = cubit.currentOpeningBalance;

        if (state is OpeningBalanceLoading || opening == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _descriptionController.text = opening.description ?? '';
        _notesController.text = opening.notes ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Opening Balance'),
            actions: [
              IconButton(
                onPressed: opening.id != null
                    ? () => cubit.postCurrentOpeningBalance()
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Post',
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, opening),
                  const SizedBox(height: 16),
                  _buildLines(context, opening),
                  const SizedBox(height: 16),
                  _buildTotals(opening),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Opening Balance'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showLineDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Line'),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, OpeningBalanceEntity opening) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: opening.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Number',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: opening.entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        context
                            .read<OpeningBalanceCubit>()
                            .updateFormData(entryDate: picked);
                      }
                    },
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Entry date'),
                      child: Text(
                        opening.entryDate.toLocal().toString().split(' ').first,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => context
                  .read<OpeningBalanceCubit>()
                  .updateFormData(description: value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
              onChanged: (value) =>
                  context.read<OpeningBalanceCubit>().updateFormData(notes: value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLines(BuildContext context, OpeningBalanceEntity opening) {
    if (opening.lines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No lines added yet'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: opening.lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          return ListTile(
            leading: CircleAvatar(child: Text('${line.lineNumber}')),
            title: Text('${line.accountCode} - ${line.accountName}'),
            subtitle: Text('Debit: ${line.debit} | Credit: ${line.credit}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  context.read<OpeningBalanceCubit>().removeLine(index),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotals(OpeningBalanceEntity opening) {
    final balanced = opening.isBalanced;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total debit: ${opening.totalDebit.toStringAsFixed(2)}'),
                Text('Total credit: ${opening.totalCredit.toStringAsFixed(2)}'),
              ],
            ),
            Chip(
              label: Text(balanced ? 'Balanced' : 'Not balanced'),
              backgroundColor: balanced ? Colors.green.shade100 : Colors.red.shade100,
              labelStyle: TextStyle(
                color: balanced ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLineDialog(BuildContext context) async {
    final cubit = context.read<OpeningBalanceCubit>();
    final accounts = cubit.availableAccounts;

    if (accounts.isEmpty) {
      _showSnack('Accounts are not loaded yet', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? accountId = accounts.first.id;
    final debitController = TextEditingController(text: '0');
    final creditController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add line'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: accountId,
                decoration: const InputDecoration(labelText: 'Account'),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a.id,
                        child: Text('${a.code} - ${a.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => accountId = value,
              ),
              TextFormField(
                controller: debitController,
                decoration: const InputDecoration(labelText: 'Debit'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: creditController,
                decoration: const InputDecoration(labelText: 'Credit'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final debit = double.tryParse(debitController.text) ?? 0;
              final credit = double.tryParse(creditController.text) ?? 0;
              if ((debit <= 0 && credit <= 0) ||
                  (debit > 0 && credit > 0) ||
                  accountId == null) {
                _showSnack(
                  'Enter either debit or credit for one account',
                  isError: true,
                );
                return;
              }

              final account =
                  accounts.firstWhere((element) => element.id == accountId);

              final line = OpeningBalanceLineEntity(
                lineNumber: cubit.currentOpeningBalance!.lines.length + 1,
                accountId: account.id!,
                accountCode: account.code,
                accountName: account.name,
                currencyId: cubit.currentOpeningBalance!.currencyId,
                currencyCode: cubit.currentOpeningBalance!.currencyCode,
                debit: debit,
                credit: credit,
              );

              cubit.addLine(line);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;
    context.read<OpeningBalanceCubit>().saveOpeningBalance();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
