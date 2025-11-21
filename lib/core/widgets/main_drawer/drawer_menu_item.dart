import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/models/nav_item.dart';

class DrawerMenuItem extends StatefulWidget {
  final NavItem item;
  final bool isChild;

  const DrawerMenuItem({Key? key, required this.item, this.isChild = false})
    : super(key: key);

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

  void _onTap(BuildContext context) {
    if (widget.item.children.isNotEmpty) {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _rotationController.forward();
        } else {
          _rotationController.reverse();
        }
      });
    } else {
      GoRouter.of(context).pushNamed(widget.item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasChildren = item.children.isNotEmpty;
    final bool isChild = widget.isChild;

    return Column(
      children: [
        InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isChild ? 32 : 16,
              vertical: isChild ? 8 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isChild
                  ? null
                  : Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.8),
                    ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: isChild ? 12 : 14,
                        fontWeight: isChild ? FontWeight.bold : FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(item.icon, size: isChild ? 15 : 18),
                  ],
                ),
                if (hasChildren)
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotationController.value * 3.14 / 2,
                      child: child,
                    ),
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: item.children.map((child) {
              return DrawerMenuItem(item: child, isChild: true);
            }).toList(),
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
