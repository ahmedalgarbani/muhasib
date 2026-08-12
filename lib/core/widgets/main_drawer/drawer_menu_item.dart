import 'package:flutter/material.dart';
import 'package:muhasib/core/models/nav_item.dart';
import 'package:muhasib/core/route/app_router.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';

class DrawerMenuItem extends StatefulWidget {
  final NavItem item;
  final bool isChild;

  const DrawerMenuItem({super.key, required this.item, this.isChild = false});

  @override
  State<DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<DrawerMenuItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.item.children.isNotEmpty) {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _rotationController.forward();
        } else {
          _rotationController.reverse();
        }
      });
      return;
    }

    closeAppDrawer();
    router.push(widget.item.route);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasChildren = item.children.isNotEmpty;
    final isChild = widget.isChild;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isChild ? 28 : 8,
            vertical: 2,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              splashColor: AppColors.blue100,
              highlightColor: AppColors.blue50.withValues(alpha: 0.5),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isChild ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: _isExpanded ? AppColors.blue50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    _DrawerItemIcon(icon: item.icon, isChild: isChild),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: isChild ? 13 : 14.5,
                          fontWeight: FontWeight.w600,
                          color: isChild
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (hasChildren)
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (_, child) => Transform.rotate(
                          angle: _rotationController.value * 3.14159 / 2,
                          child: child,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: item.children
                .map((child) => DrawerMenuItem(item: child, isChild: true))
                .toList(),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _DrawerItemIcon extends StatelessWidget {
  final IconData icon;
  final bool isChild;

  const _DrawerItemIcon({required this.icon, required this.isChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isChild ? AppColors.gray100 : AppColors.blue100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: isChild ? 16 : 18,
        color: isChild ? AppColors.textSecondary : AppColors.blue700,
      ),
    );
  }
}
