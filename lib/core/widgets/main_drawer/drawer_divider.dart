import 'package:flutter/material.dart';

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: Theme.of(context).dividerColor,
    );
  }
}
