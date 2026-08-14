import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/widgets/app_drawer_controller.dart';
import 'package:muhasib/core/widgets/root_shell.dart';
import 'package:muhasib/core/widgets/main_drawer/main_app_drawer.dart';

void main() {
  setUp(() {
    appDrawerOpen.value = false;
  });

  testWidgets('RootShell renders child when drawer is closed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RootShell(
          child: Scaffold(
            body: Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
    expect(find.byType(MainAppDrawer), findsNothing);
  });

  testWidgets('RootShell opens drawer, renders overlay & tooltips without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RootShell(
          child: Scaffold(
            body: Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);

    // Open drawer
    openAppDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Finish animation

    // Verify MainAppDrawer is displayed
    expect(find.byType(MainAppDrawer), findsOneWidget);
    expect(find.text('محاسب'), findsWidgets);
    expect(find.byTooltip('إغلاق'), findsOneWidget);

    // Close drawer via closeAppDrawer
    closeAppDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Finish animation

    expect(find.byType(MainAppDrawer), findsNothing);
  });

  testWidgets('RootShell closes drawer when tapping backdrop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RootShell(
          child: Scaffold(
            body: Text('Test Content'),
          ),
        ),
      ),
    );

    openAppDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(MainAppDrawer), findsOneWidget);

    // Tap backdrop overlay (left side of the screen)
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(appDrawerOpen.value, isFalse);
    expect(find.byType(MainAppDrawer), findsNothing);
  });
}
