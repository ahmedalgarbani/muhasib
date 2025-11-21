import 'package:flutter/material.dart';

class MainDrawerHeaderIcon extends StatelessWidget {
  final IconData icon;

  const MainDrawerHeaderIcon({Key? key, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: () {},
      ),
    );
  }
}
