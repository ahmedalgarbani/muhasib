class AccountConstants {
  static const List<Map<String, dynamic>> accountTypes = [
    {'id': 0, 'name': 'أصول'},
    {'id': 1, 'name': 'خصوم'},
    {'id': 2, 'name': 'حقوق ملكية'},
    {'id': 3, 'name': 'إيرادات'},
    {'id': 4, 'name': 'مصروفات'},
  ];

  static const List<Map<String, dynamic>> classificationTypes = [
    {'id': 0, 'name': 'محلي'},
    {'id': 1, 'name': 'دولي'},
  ];

  static String getAccountTypeName(int id) {
    return accountTypes.firstWhere((e) => e['id'] == id, orElse: () => {'name': 'غير معروف'})['name'];
  }

  static String getClassificationName(int id) {
    return classificationTypes.firstWhere((e) => e['id'] == id, orElse: () => {'name': 'غير معروف'})['name'];
  }
}
