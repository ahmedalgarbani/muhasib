import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/widgets/region_card_widget.dart';

/// Standalone Regions List Widget with search field and region cards list.
class RegionsListWidget extends StatelessWidget {
  final List<RegionEntity> regions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(RegionEntity) onRegionTap;
  final Function(RegionEntity) onRegionEdit;
  final Function(RegionEntity) onRegionDelete;

  const RegionsListWidget({
    super.key,
    required this.regions,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRegionTap,
    required this.onRegionEdit,
    required this.onRegionDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextInputField(
            controller: searchController,
            hint: 'بحث في المناطق...',
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
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final region = regions[index];
              return RegionCardWidget(
                region: region,
                onTap: () => onRegionTap(region),
                onEdit: () => onRegionEdit(region),
                onDelete: () => onRegionDelete(region),
              );
            },
          ),
        ),
      ],
    );
  }
}
