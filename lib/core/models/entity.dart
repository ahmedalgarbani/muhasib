abstract class Entity {
  String? get pk => null;
  set pk(String? value) {}
  String? get route => null;
  String? get title => null;
  Map<dynamic, dynamic> get toJson => const {};
}
