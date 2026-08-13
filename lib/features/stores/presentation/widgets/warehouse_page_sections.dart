import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class WarehouseMenuCard extends StatelessWidget {
  const WarehouseMenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: color,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WarehouseTypeSelector extends StatelessWidget {
  const WarehouseTypeSelector({
    super.key,
    required this.types,
    required this.value,
    required this.onChanged,
    this.height = 90,
    this.width = 100,
  });

  final List<Map<String, dynamic>> types;
  final String value;
  final ValueChanged<String> onChanged;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = types[index];
          final selected = value == type['value'];
          final color = type['color'] as Color;
          return GestureDetector(
            onTap: () => onChanged(type['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? color : Colors.grey[300]!,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: selected ? color : Colors.grey[600],
                    size: height == 100 ? 32 : 28,
                  ),
                  SizedBox(height: height == 100 ? 8 : 4),
                  Text(
                    type['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: height == 100 ? null : 12,
                      color: selected ? color : Colors.grey[600],
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WarehouseDocumentCard extends StatelessWidget {
  const WarehouseDocumentCard({
    super.key,
    required this.colorScheme,
    required this.numberController,
    required this.date,
    required this.numberLabel,
    required this.onSelectDate,
  });

  final ColorScheme colorScheme;
  final TextEditingController numberController;
  final DateTime date;
  final String numberLabel;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'بيانات المستند',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: numberController,
                    label: numberLabel,
                    hint: numberLabel,
                    prefixIcon: Icons.tag,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: onSelectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      child: Text('${date.year}/${date.month}/${date.day}'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WarehouseNotesCard extends StatelessWidget {
  const WarehouseNotesCard({
    super.key,
    required this.colorScheme,
    required this.controller,
    required this.hint,
  });
  final ColorScheme colorScheme;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: controller,
              label: 'الملاحظات',
              hint: hint,
              prefixIcon: Icons.comment,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class TransferWarehouseSelection extends StatelessWidget {
  const TransferWarehouseSelection({
    super.key,
    required this.colorScheme,
    required this.source,
    required this.destination,
    required this.onSourceChanged,
    required this.onDestinationChanged,
  });
  final ColorScheme colorScheme;
  final WarehouseEntity? source;
  final WarehouseEntity? destination;
  final ValueChanged<WarehouseEntity?> onSourceChanged;
  final ValueChanged<WarehouseEntity?> onDestinationChanged;

  @override
  Widget build(BuildContext context) => CustomCardContainer(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warehouse, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'المخازن',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<WarehousesCubit, WarehousesState>(
            builder: (context, state) {
              final warehouses = state is WarehousesLoaded
                  ? state.warehouses
                  : <WarehouseEntity>[];
              return Row(
                children: [
                  Expanded(
                    child: CustomDropdownField<WarehouseEntity>(
                      value: source,
                      hint: 'اختر المخزن المصدر',
                      prefixIcon: const Icon(Icons.output),
                      items: warehouses
                          .map(
                            (warehouse) => DropdownMenuItem(
                              value: warehouse,
                              child: Text(warehouse.name),
                            ),
                          )
                          .toList(),
                      onChanged: onSourceChanged,
                      validator: (value) =>
                          value == null ? 'يرجى اختيار المخزن المصدر' : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  Expanded(
                    child: CustomDropdownField<WarehouseEntity>(
                      value: destination,
                      hint: 'اختر المخزن الوجهة',
                      prefixIcon: const Icon(Icons.input),
                      items: warehouses
                          .where((warehouse) => warehouse != source)
                          .map(
                            (warehouse) => DropdownMenuItem(
                              value: warehouse,
                              child: Text(warehouse.name),
                            ),
                          )
                          .toList(),
                      onChanged: onDestinationChanged,
                      validator: (value) =>
                          value == null ? 'يرجى اختيار المخزن الوجهة' : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class WarehouseActionButtons extends StatelessWidget {
  const WarehouseActionButtons({
    super.key,
    required this.onSecondary,
    required this.onPrimary,
    required this.primaryLabel,
    this.disablePrimary = false,
  });
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final bool disablePrimary;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: HasibButton(
          label: 'حفظ كمسودة',
          leading: const Icon(Icons.save),
          onPressed: onSecondary,
          variant: HasibButtonVariant.secondary,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: HasibButton(
          label: primaryLabel,
          leading: const Icon(Icons.send, color: Colors.white),
          onPressed: disablePrimary ? null : onPrimary,
          variant: HasibButtonVariant.primary,
        ),
      ),
    ],
  );
}

class InventoryLineItem extends StatelessWidget {
  const InventoryLineItem({
    super.key,
    required this.line,
    required this.index,
    required this.countMode,
    required this.onChanged,
    required this.onDelete,
  });
  final InventoryLineEntity line;
  final int index;
  final bool countMode;
  final ValueChanged<double> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final difference = line.actualQuantity - line.quantity;
    final positive = difference >= 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: positive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: positive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        line.statement.isNotEmpty ? line.statement : 'صنف ${index + 1}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'متوقع: ${line.quantity} | فعلي: ${line.actualQuantity}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'الفرق: ${difference > 0 ? '+' : ''}$difference',
            style: TextStyle(
              fontSize: 12,
              color: positive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      trailing: countMode
          ? SizedBox(
              width: 100,
              child: TextInputField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                hint: '0',
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) => onChanged(double.tryParse(value) ?? 0),
                controller: TextEditingController(
                  text: line.actualQuantity.toString(),
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
    );
  }
}
