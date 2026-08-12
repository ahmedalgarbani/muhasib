import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/bank_card_widget.dart';

/// Standalone Banks List Widget with search bar and bank cards list.
class BanksListWidget extends StatelessWidget {
  final List<BankEntity> banks;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(BankEntity) onBankTap;
  final Function(BankEntity) onBankEdit;
  final Function(BankEntity) onBankDelete;

  const BanksListWidget({
    super.key,
    required this.banks,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onBankTap,
    required this.onBankEdit,
    required this.onBankDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'بحث في البنوك...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
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
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];
              return BankCardWidget(
                bank: bank,
                onTap: () => onBankTap(bank),
                onEdit: () => onBankEdit(bank),
                onDelete: () => onBankDelete(bank),
              );
            },
          ),
        ),
      ],
    );
  }
}
