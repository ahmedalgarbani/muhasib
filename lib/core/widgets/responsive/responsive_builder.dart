import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstant.maxTabletWidth) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppConstant.maxMobileWidth) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
