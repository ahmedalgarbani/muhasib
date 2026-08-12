import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/accounts/presentation/pages/accounts_tree_view.dart';

class CurrentAccountCard extends StatelessWidget {
  const CurrentAccountCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return AccountsTreeScreen();
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[50],
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text(
                'الصندوق الرئيسي',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
