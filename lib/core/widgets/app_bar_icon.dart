
import 'package:flutter/material.dart';

class AppBarIcon extends StatelessWidget {
  final IconData icon;

  const AppBarIcon({Key? key, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87),
      onPressed: () {},
    );
  }
}
