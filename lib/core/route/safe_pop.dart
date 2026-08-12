import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';

/// Extension on BuildContext to safely pop pages without throwing GoRouter assertion errors
/// when trying to pop the root page off the navigation stack.
extension SafePopContext on BuildContext {
  /// Safely pops the current route if popping is possible via GoRouter or Navigator.
  /// If neither can pop (e.g. root page or shell branch root),
  /// it navigates to [fallbackRoute] (defaults to [AppRoutes.home]) instead of throwing an AssertionError.
  void safePop([Object? result, String fallbackRoute = AppRoutes.home]) {
    if (canPop()) {
      pop(result);
    } else if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop(result);
    } else {
      go(fallbackRoute);
    }
  }
}
