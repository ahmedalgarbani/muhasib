import 'package:hasib_lib/base/entity.dart';

/// Lightweight [Entity] implementation for wrapping simple string options.
class SimpleEntity extends Entity {
  SimpleEntity({
    required this.id,
    required this.titleValue,
    this.routeValue = 'simple_entity',
  });

  final String id;
  final String titleValue;
  final String routeValue;

  @override
  String? get pk => id;

  @override
  String? get route => routeValue;

  @override
  String? get title => titleValue;

  @override
  Map<dynamic, dynamic> get toJson => {
        'id': id,
        'title': titleValue,
        'route': routeValue,
      };

  @override
  set pk(String? value) {
    // Immutable entity; ignore external mutations.
  }
}
