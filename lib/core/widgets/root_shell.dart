import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';

/// Wraps the whole navigator and hosts the app-wide drawer as an overlay.
///
/// Because it sits above the Navigator it can display the drawer on top of any
/// page, including pages pushed with `context.push`.
class RootShell extends StatefulWidget {
  final Widget child;

  const RootShell({super.key, required this.child});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    appDrawerOpen.addListener(_onDrawerChanged);
  }

  void _onDrawerChanged() {
    if (appDrawerOpen.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    appDrawerOpen.removeListener(_onDrawerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.value == 0) {
              return const SizedBox.shrink();
            }
            final drawerWidth = (MediaQuery.sizeOf(context).width * 0.82).clamp(
              0.0,
              360.0,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: closeAppDrawer,
                    child: Container(
                      color: Colors.black54.withValues(alpha: _fade.value),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: drawerWidth,
                  child: FractionalTranslation(
                    translation: _slide.value,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) => Material(
                            color: Colors.white,
                            elevation: 16,
                            shadowColor: Colors.black38,
                            child: const SafeArea(
                              right: false,
                              child: MainAppDrawer(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
