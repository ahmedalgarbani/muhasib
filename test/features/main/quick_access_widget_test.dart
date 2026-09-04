import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_item.dart';
import 'package:muhasib/features/main/presentation/widgets/quick_access_section.dart';

void main() {
  group('QuickAccess widgets test', () {
    testWidgets('QuickAccessItem renders without overflow in tight constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 70,
              height: 75,
              child: QuickAccessItem(
                icon: Icons.point_of_sale_rounded,
                label: 'المبيعات',
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('المبيعات'), findsOneWidget);
    });

    testWidgets('QuickAccessSection renders without overflow on 412px screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessSection(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('المبيعات'), findsOneWidget);
      expect(find.text('الوصول السريع'), findsOneWidget);
    });

    testWidgets('QuickAccessSection renders without overflow on 360px screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessSection(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('المبيعات'), findsOneWidget);
    });

    testWidgets(
        'QuickAccessSection renders without overflow with large text scale on 360px screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessSection(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('المبيعات'), findsOneWidget);
    });
  });
}
