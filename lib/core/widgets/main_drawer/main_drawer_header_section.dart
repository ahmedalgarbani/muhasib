import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/main_drawer/main_drawer_header_icon.dart';

class MainDrawerHeaderSection extends StatelessWidget {
  const MainDrawerHeaderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: const [
                    MainDrawerHeaderIcon(icon: Icons.nightlight_round),
                    MainDrawerHeaderIcon(icon: Icons.language),
                    MainDrawerHeaderIcon(icon: Icons.palette),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'محاسب',
              style: TextStyle(
                color: Color(0xFFC4A053),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
