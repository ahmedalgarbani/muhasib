import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/cashbox_card_widget.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

/// Standalone Cashboxes List Widget with search bar and cashbox cards list.
class CashboxesListWidget extends StatelessWidget {
  final List<CashboxEntity> cashboxes;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(CashboxEntity) onCashboxTap;
  final Function(CashboxEntity) onCashboxEdit;
  final Function(CashboxEntity) onCashboxSetMain;
  final Function(CashboxEntity) onCashboxDelete;

  const CashboxesListWidget({
    super.key,
    required this.cashboxes,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCashboxTap,
    required this.onCashboxEdit,
    required this.onCashboxSetMain,
    required this.onCashboxDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextInputField(
            controller: searchController,
            hint: 'بحث في الصناديق...',
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cashboxes.length,
            itemBuilder: (context, index) {
              final cashbox = cashboxes[index];
              return CashboxCardWidget(
                cashbox: cashbox,
                onTap: () => onCashboxTap(cashbox),
                onEdit: () => onCashboxEdit(cashbox),
                onSetMain: () => onCashboxSetMain(cashbox),
                onDelete: () => onCashboxDelete(cashbox),
              );
            },
          ),
        ),
      ],
    );
  }
}
