import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/widgets/app_bar_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String? title;
  final List<Widget>? actions;

  const CustomAppBar({Key? key, this.onMenuPressed, this.title, this.actions})
    : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 26),
              onPressed: onMenuPressed,
            )
          : null,
      title: Text(
        title ?? 'محاسب',
        style: const TextStyle(
          color: Color(0xFF4A90E2),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions:
          actions ??
          [
            AppBarIcon(icon: Icons.cloud_outlined),
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
