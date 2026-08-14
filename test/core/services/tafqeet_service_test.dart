import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/services/tafqeet_service.dart';

void main() {
  group('TafqeetService', () {
    test('converts zero', () {
      expect(TafqeetService.convert(0), 'صفر ريال');
    });

    test('converts whole hundreds and thousands', () {
      expect(TafqeetService.convert(100), 'مئة ريالاً');
      expect(TafqeetService.convert(1000), 'ألف ريالاً');
      expect(TafqeetService.convert(1050), 'ألف وخمسون ريالاً');
    });

    test('converts amount with fraction', () {
      expect(
        TafqeetService.convert(125.70),
        'مئة وخمسة وعشرون ريالاً وسبعون هللة',
      );
    });

    test('converts small plural amounts', () {
      expect(TafqeetService.convert(3.5), 'ثلاثة ريالات وخمسون هللة');
    });

    test('converts single unit', () {
      expect(TafqeetService.convert(1), 'ريال واحد');
      expect(TafqeetService.convert(0.01), 'صفر ريال وهللة واحدة');
    });

    test('converts millions up to billions range', () {
      expect(
        TafqeetService.convert(1234567.25),
        'مليون ومئتان وأربعة وثلاثون ألفاً وخمسمئة وسبعة وستون ريالاً وخمسة وعشرون هللة',
      );
    });
  });
}
