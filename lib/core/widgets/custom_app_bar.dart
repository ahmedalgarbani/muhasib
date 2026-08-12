import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/app_bar_icon.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';

/// Uniform app bar used across the whole app.
///
/// By default it shows a menu button that opens the app-wide drawer
/// ([RootShell]). Pass [showBack] = true to show a back arrow instead
/// (e.g. on detail/form pages), or pass [onMenuPressed] to fully override
/// the leading action.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool showBack;
  final String? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    this.onMenuPressed,
    this.showBack = false,
    this.title,
    this.actions,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  Widget? _buildLeading(BuildContext context) {
    if (onMenuPressed != null) {
      return IconButton(
        icon: const Icon(Icons.menu, color: Colors.black, size: 26),
        onPressed: onMenuPressed,
      );
    }
    if (showBack) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.black, size: 26),
      onPressed: toggleAppDrawer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: _buildLeading(context),
      title: Text(
        title ?? 'محاسب',
        style: const TextStyle(
          color: AppColors.customBlue,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions:
          actions ??
          [
            GestureDetector(
              child: AppBarIcon(icon: Icons.settings_outlined),
              onTap: () {
                GoRouter.of(context).go(AppRoutes.settings);
              },
            ),
          ],
    );
  }
}
