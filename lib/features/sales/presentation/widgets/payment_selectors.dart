import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/banks_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// Dynamic bank selector that loads banks from database
class BankSelectorDropdown extends StatelessWidget {
  final BankEntity? selectedBank;
  final ValueChanged<BankEntity?> onChanged;
  final String? labelText;
  final bool isRequired;

  const BankSelectorDropdown({
    Key? key,
    this.selectedBank,
    required this.onChanged,
    this.labelText = 'البنك',
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BanksCubit>()..loadActiveBanks(),
      child: BlocBuilder<BanksCubit, BanksState>(
        builder: (context, state) {
          List<BankEntity> banks = [];
          bool isLoading = false;
          
          if (state is BanksLoading) {
            isLoading = true;
          } else if (state is BanksLoaded) {
            banks = state.banks;
          }

          if (isLoading) {
            return _buildLoadingDropdown();
          }

          if (banks.isEmpty) {
            return _buildEmptyDropdown(context);
          }

          return DropdownButtonFormField<BankEntity>(
            value: selectedBank,
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: const Icon(Icons.account_balance),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            items: banks.map((bank) {
              return DropdownMenuItem<BankEntity>(
                value: bank,
                child: Row(
                  children: [
                    Text(bank.name),
                    if (bank.branchName != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${bank.branchName})',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired 
                ? (value) => value == null ? 'يرجى اختيار البنك' : null
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingDropdown() {
    return DropdownButtonFormField<BankEntity>(
      value: null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: const [],
      onChanged: null,
    );
  }

  Widget _buildEmptyDropdown(BuildContext context) {
    return DropdownButtonFormField<BankEntity>(
      value: null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.account_balance),
        helperText: 'لا توجد بنوك - أضف من الإعدادات',
        helperStyle: const TextStyle(color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: const [],
      onChanged: null,
    );
  }
}

/// Dynamic cashbox/fund selector that loads cashboxes from database
class CashboxSelectorDropdown extends StatelessWidget {
  final CashboxEntity? selectedCashbox;
  final ValueChanged<CashboxEntity?> onChanged;
  final String? labelText;
  final bool isRequired;

  const CashboxSelectorDropdown({
    Key? key,
    this.selectedCashbox,
    required this.onChanged,
    this.labelText = 'الصندوق',
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CashboxesCubit>()..loadActiveCashboxes(),
      child: BlocBuilder<CashboxesCubit, CashboxesState>(
        builder: (context, state) {
          List<CashboxEntity> cashboxes = [];
          bool isLoading = false;
          
          if (state is CashboxesLoading) {
            isLoading = true;
          } else if (state is CashboxesLoaded) {
            cashboxes = state.cashboxes;
          }

          if (isLoading) {
            return _buildLoadingDropdown();
          }

          if (cashboxes.isEmpty) {
            return _buildEmptyDropdown(context);
          }

          return DropdownButtonFormField<CashboxEntity>(
            value: selectedCashbox,
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: const Icon(Icons.account_balance_wallet),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            items: cashboxes.map((cashbox) {
              return DropdownMenuItem<CashboxEntity>(
                value: cashbox,
                child: Row(
                  children: [
                    if (cashbox.isMainFund)
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                    if (cashbox.isMainFund) const SizedBox(width: 4),
                    Text(cashbox.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired 
                ? (value) => value == null ? 'يرجى اختيار الصندوق' : null
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingDropdown() {
    return DropdownButtonFormField<CashboxEntity>(
      value: null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: const [],
      onChanged: null,
    );
  }

  Widget _buildEmptyDropdown(BuildContext context) {
    return DropdownButtonFormField<CashboxEntity>(
      value: null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.account_balance_wallet),
        helperText: 'لا توجد صناديق - أضف من الإعدادات',
        helperStyle: const TextStyle(color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: const [],
      onChanged: null,
    );
  }
}
