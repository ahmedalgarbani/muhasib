import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/detail_row.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';

class PartyProfileSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const PartyProfileSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(77),
        ),
      ),
    );
  }
}

class PartyProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PartyProfileErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class PartyProfileEmptyState extends StatelessWidget {
  final String title;
  final IconData icon;

  const PartyProfileEmptyState({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: colorScheme.outline, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class PartyProfileCard extends StatelessWidget {
  final Customer party;
  final bool isSupplier;
  final VoidCallback onTap;

  const PartyProfileCard({
    super.key,
    required this.party,
    required this.isSupplier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasBalance = party.balance > 0;
    final isOverLimit =
        !isSupplier &&
        party.creditLimit > 0 &&
        party.balance > party.creditLimit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  PartyAvatar(party: party, isSupplier: isSupplier),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (party.phone?.isNotEmpty ?? false)
                          Text(
                            party.phone!,
                            style: TextStyle(
                              color: colorScheme.outline,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${party.balance.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSupplier
                              ? (hasBalance ? Colors.orange : Colors.green)
                              : (hasBalance ? Colors.red : Colors.green),
                        ),
                      ),
                      Text(
                        isSupplier
                            ? (hasBalance ? 'له' : 'متوازن')
                            : (hasBalance ? 'عليه' : 'متوازن'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSupplier
                              ? (hasBalance ? Colors.orange : Colors.green)
                              : (hasBalance ? Colors.red : Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (party.creditLimit > 0)
                _CreditLimitSummary(
                  party: party,
                  isSupplier: isSupplier,
                  isOverLimit: isOverLimit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartyAvatar extends StatelessWidget {
  final Customer party;
  final bool isSupplier;

  const PartyAvatar({super.key, required this.party, required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: isSupplier
          ? colorScheme.secondaryContainer
          : colorScheme.primaryContainer,
      child: Text(
        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: isSupplier
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreditLimitSummary extends StatelessWidget {
  final Customer party;
  final bool isSupplier;
  final bool isOverLimit;

  const _CreditLimitSummary({
    required this.party,
    required this.isSupplier,
    required this.isOverLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isSupplier) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 16, color: colorScheme.outline),
            const SizedBox(width: 8),
            Text(
              'حد الائتمان: ${party.creditLimit.toStringAsFixed(0)} ر.س',
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: (party.balance / party.creditLimit).clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                isOverLimit ? Colors.red : colorScheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حد الائتمان: ${party.creditLimit.toStringAsFixed(0)} ر.س',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
              if (isOverLimit)
                const Text(
                  'تجاوز الحد',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PartyDetailsSheet extends StatelessWidget {
  final Customer party;
  final bool isSupplier;

  const PartyDetailsSheet({
    super.key,
    required this.party,
    required this.isSupplier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceColor = isSupplier
        ? (party.balance > 0 ? Colors.orange : Colors.green)
        : (party.balance > 0 ? Colors.red : Colors.green);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
            ),
            Row(
              children: [
                PartyAvatar(party: party, isSupplier: isSupplier),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        party.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (party.phone != null)
                        Text(
                          party.phone!,
                          style: TextStyle(color: colorScheme.outline),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balanceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الرصيد الحالي',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${party.balance.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (party.creditLimit > 0)
              DetailRow(
                icon: Icons.credit_card,
                label: 'حد الائتمان',
                value: '${party.creditLimit.toStringAsFixed(0)} ر.س',
              ),
            if (party.address?.isNotEmpty ?? false)
              DetailRow(
                icon: Icons.location_on,
                label: 'العنوان',
                value: party.address!,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.article),
                    label: const Text('كشف حساب'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.receipt),
                    label: Text(isSupplier ? 'فاتورة شراء' : 'فاتورة جديدة'),
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

void showPartyDetailsSheet(
  BuildContext context,
  Customer party,
  bool isSupplier,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg20)),
    ),
    builder: (_) => PartyDetailsSheet(party: party, isSupplier: isSupplier),
  );
}

class PartyAccountNotice extends StatelessWidget {
  final bool isSupplier;

  const PartyAccountNotice({super.key, required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    final color = isSupplier ? Colors.orange : Colors.blue;
    final label = isSupplier ? 'المورد' : 'العميل';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'سيتم إنشاء حساب تلقائياً لـ $label في شجرة الحسابات',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
