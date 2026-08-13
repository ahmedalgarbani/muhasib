import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/banks_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';
import 'package:muhasib/core/theme/app_radius.dart';

import 'package:muhasib/features/sales/presentation/widgets/components/dropdown_state_widgets.dart';

/// Dynamic bank selector that loads banks from database
class BankSelectorDropdown extends StatelessWidget {
  final BankEntity? selectedBank;
  final ValueChanged<BankEntity?> onChanged;
  final String? labelText;
  final bool isRequired;

  const BankSelectorDropdown({
    super.key,
    this.selectedBank,
    required this.onChanged,
    this.labelText = 'البنك',
    this.isRequired = false,
  });

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
            return LoadingDropdownWidget<BankEntity>(label: labelText ?? '');
          }

          if (banks.isEmpty) {
            return EmptyDropdownWidget<BankEntity>(
              label: labelText ?? '',
              hint: 'لا توجد بنوك - أضف من الإعدادات',
              icon: Icons.account_balance,
            );
          }

          return CustomDropdownField<BankEntity>(
            value: selectedBank,
            label: labelText ?? '',
            prefixIcon: const Icon(Icons.account_balance),
            isRequired: isRequired,
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}

/// Dynamic cashbox/fund selector that loads cashboxes from database
class CashboxSelectorDropdown extends StatelessWidget {
  final CashboxEntity? selectedCashbox;
  final ValueChanged<CashboxEntity?> onChanged;
  final String? labelText;
  final bool isRequired;

  const CashboxSelectorDropdown({
    super.key,
    this.selectedCashbox,
    required this.onChanged,
    this.labelText = 'الصندوق',
    this.isRequired = false,
  });

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
            return LoadingDropdownWidget<CashboxEntity>(label: labelText ?? '');
          }

          if (cashboxes.isEmpty) {
            return EmptyDropdownWidget<CashboxEntity>(
              label: labelText ?? '',
              hint: 'لا توجد صناديق - أضف من الإعدادات',
              icon: Icons.account_balance_wallet,
            );
          }

          return CustomDropdownField<CashboxEntity>(
            value: selectedCashbox,
            label: labelText ?? '',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            isRequired: isRequired,
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
}

