import 'package:muhasib/core/enums/account_type.dart';
import 'package:muhasib/core/enums/classification_type.dart';

/// @Deprecated — استخدم Enums المركزية مباشرة
/// Kept for backward compatibility — delegates to central enums
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
    return AccountType.tryFromValue(id)?.labelAr ?? 'غير معروف';
  }

  static String getClassificationName(int id) {
    return ClassificationType.tryFromValue(id)?.labelAr ?? 'غير معروف';
  }
}
