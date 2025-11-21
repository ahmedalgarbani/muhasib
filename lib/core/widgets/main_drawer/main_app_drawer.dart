import 'package:flutter/material.dart';
import 'package:muhasib/core/route/app_navigator.dart';
import 'package:muhasib/core/widgets/main_drawer/current_account_card.dart';
import 'package:muhasib/core/widgets/main_drawer/drawer_menu_item.dart';
import 'package:muhasib/core/widgets/main_drawer/main_drawer_header_section.dart';

class MainAppDrawer extends StatelessWidget {
  const MainAppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          MainDrawerHeaderSection(),
          const CurrentAccountCard(),
          const SizedBox(height: 8),
          ...AppNavigator.items.map((item) => DrawerMenuItem(item: item)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
