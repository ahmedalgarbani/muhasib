import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/features/main/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';

class MainScaffoldShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffoldShell({Key? key, required this.navigationShell})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: const MainAppDrawer(),
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
