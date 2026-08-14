import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/data/models/account_model.dart';
import 'package:muhasib/features/accounts/domain/enums/account_type.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onShowMovements;
  final String Function(double) formatNumber;

  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onShowMovements,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccountColors.getColors(AccountType.assets);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    double baseFont = isTablet ? 16 : 12;
    double padding = isTablet ? 24 : 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          onTap: account.isMaster ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.background,
              border: Border.all(color: colors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Header Row ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        account.isMaster
                            ? Icons.folder_open
                            : Icons.description,
                        color: colors.icon,
                        size: isTablet ? 28 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: baseFont * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            account.code,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: baseFont,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 8,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(AppRadius.lg20),
                      ),
                      child: Text(
                        account.isMaster
                            ? 'رئيسي'
                            : (account.type == 1 || account.type == 0)
                            ? 'مدين'
                            : 'دائن',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: baseFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 12),

                /// --- Account Number ---
                Container(
                  padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'رقم الحساب:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: baseFont,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          account.code,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: baseFont * 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 16 : 12),

                /// --- Balance Row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الرصيد الحالي',
                      style: TextStyle(color: Colors.grey, fontSize: baseFont),
                    ),
                    Row(
                      children: [
                        Icon(
                          (account.national == 1 || account.national == 0)
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: isTablet ? 18 : 14,
                          color:
                              (account.national == 1 || account.national == 0)
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatNumber(account.balance),
                          style: TextStyle(
                            color: colors.text,
                            fontSize: baseFont * 1.4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ريال',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: baseFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 12),

                /// --- Footer (button or hint) ---
                Container(
                  padding: EdgeInsets.only(top: isTablet ? 16 : 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: account.isMaster
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chevron_left,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'اضغط لعرض الحسابات الفرعية',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: baseFont,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: HasibButton(
                            label: 'عرض الحركات',
                            onPressed: onShowMovements,
                            leading: Icon(
                              Icons.description,
                              size: baseFont + 2,
                            ),
                            variant: HasibButtonVariant.secondary,
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 12 : 8,
                            ),
                            fontSize: baseFont * 1.1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
