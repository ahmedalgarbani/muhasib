import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';

class LoadingDropdownWidget<T> extends StatelessWidget {
  final String label;

  const LoadingDropdownWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomDropdownField<T>(
      value: null,
      label: label,
      prefixIcon: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      items: const [],
      onChanged: null,
    );
  }
}

class EmptyDropdownWidget<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;

  const EmptyDropdownWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdownField<T>(
      value: null,
      label: label,
      hint: hint,
      prefixIcon: Icon(icon),
      items: const [],
      onChanged: null,
    );
  }
}
