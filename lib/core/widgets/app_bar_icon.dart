
import 'package:flutter/material.dart';

class AppBarIcon extends StatelessWidget {
  final IconData icon;

  const AppBarIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87),
      onPressed: () {},
    );
  }
}
