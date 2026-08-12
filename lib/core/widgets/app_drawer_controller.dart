import 'package:flutter/foundation.dart';

/// Global notifier that controls the app-wide drawer overlay.
///
/// The drawer lives in [RootShell] which wraps the whole navigator, so it is
/// reachable from every page regardless of which Scaffold is on screen.
final ValueNotifier<bool> appDrawerOpen = ValueNotifier<bool>(false);

void openAppDrawer() => appDrawerOpen.value = true;

void closeAppDrawer() => appDrawerOpen.value = false;

void toggleAppDrawer() => appDrawerOpen.value = !appDrawerOpen.value;
