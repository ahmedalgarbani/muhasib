
import 'package:flutter/material.dart';

class AccountLinkEntity {
  final int connectType;
  final String name;
  final IconData icon;
  final Color color;
  final String category;
  final bool linked;
  final String? linkedTo;
  final String? linkedAccountNumber;

  AccountLinkEntity({
    required this.connectType,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
    this.linked = false,
    this.linkedTo,
    this.linkedAccountNumber,
  });

  AccountLinkEntity copyWith({
    int? connectType,
    String? name,
    IconData? icon,
    Color? color,
    String? category,
    bool? linked,
    String? linkedTo,
    String? linkedAccountNumber,
  }) {
    return AccountLinkEntity(
      connectType: connectType ?? this.connectType,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      linked: linked ?? this.linked,
      linkedTo: linkedTo ?? this.linkedTo,
      linkedAccountNumber: linkedAccountNumber ?? this.linkedAccountNumber,
    );
  }
}
