part of 'vouchers_page.dart';

class _VoucherListItem extends StatelessWidget {
  final VoucherEntity voucher;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const _VoucherListItem({
    required this.voucher,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isReceipt = voucher.type == VoucherType.receipt;
    final color = isReceipt ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.type.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'رقم ${voucher.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    NumberFormatter.formatNumber(voucher.amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      voucher.accountName ?? 'حساب غير معروف',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDate(voucher.date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onPrint,
                    icon: const Icon(
                      Icons.print_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherDetailsSheet extends StatelessWidget {
  final VoucherEntity voucher;

  const _VoucherDetailsSheet({
    required this.voucher,
  });

  @override
  Widget build(BuildContext context) {
    final isReceipt = voucher.type == VoucherType.receipt;
    final color = isReceipt ? Colors.green : Colors.red;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'تفاصيل ${voucher.type.label}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  children: [
                    VoucherInfoCardWidget(
                      voucher: voucher,
                      color: color,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الأسطر والتوزيع المالي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (voucher.lines.isNotEmpty)
                      ...voucher.lines.map(
                        (line) => VoucherLineItemWidget(
                          line: line,
                          color: color,
                        ),
                      )
                    else
                      const VoucherSingleLineItemWidget(),
                    const SizedBox(height: 16),
                    VoucherStatementCardWidget(statement: voucher.statement),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoucherInfoCardWidget extends StatelessWidget {
  final VoucherEntity voucher;
  final Color color;

  const VoucherInfoCardWidget({
    super.key,
    required this.voucher,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'رقم السند',
            value: voucher.number.toString(),
            icon: Icons.tag,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'تاريخ السند',
            value: DateFormatter.formatDate(voucher.date),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'الحساب الرئيسي',
            value: voucher.accountName ?? '',
            icon: Icons.account_balance_wallet,
            isBold: true,
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المبلغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                NumberFormatter.formatNumber(voucher.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoucherLineItemWidget extends StatelessWidget {
  final VoucherLineEntity line;
  final Color color;

  const VoucherLineItemWidget({
    super.key,
    required this.line,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.accountName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (line.statement.isNotEmpty)
                  Text(
                    line.statement,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text(
            NumberFormatter.formatNumber(line.amount ?? 0),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class VoucherSingleLineItemWidget extends StatelessWidget {
  const VoucherSingleLineItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text(
        'هذا السند لا يحتوي على أسطر تفصيلية، تم تسجيل المبلغ بالكامل على الحساب الرئيسي.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }
}

class VoucherStatementCardWidget extends StatelessWidget {
  final String statement;

  const VoucherStatementCardWidget({super.key, required this.statement});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البيان العام',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: AppConstant.defaultPadding,
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Text(
            statement.isEmpty ? 'لا يوجد بيان مسجل لهذا السند.' : statement,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
