
import 'package:flutter/material.dart';

enum DrawerSection {
  header,
  main,
  bottom,
}

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final DrawerSection position;
  final List<NavItem> children;
  final bool hasArrow;

  const NavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.position = DrawerSection.main,
    this.children = const [],
    this.hasArrow = true,
  });
}
