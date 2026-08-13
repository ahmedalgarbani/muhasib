import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/safe_pop.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

void main() {
  testWidgets('safePop pops when pop is possible', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/first',
      routes: [
        GoRoute(
          path: '/first',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/second'),
              child: const Text('Go to Second'),
            ),
          ),
        ),
        GoRoute(
          path: '/second',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.safePop(),
              child: const Text('Safe Pop'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Go to Second'), findsOneWidget);

    await tester.tap(find.text('Go to Second'));
    await tester.pumpAndSettle();
    expect(find.text('Safe Pop'), findsOneWidget);

    await tester.tap(find.text('Safe Pop'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Second'), findsOneWidget);
  });

  testWidgets('safePop does not crash when on root page', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Page')),
        ),
        GoRoute(
          path: '/root',
          builder: (context, state) => Scaffold(
            body: HasibButton(
              onPressed: () => context.safePop(null, '/home'),
              label: 'Safe Pop Root',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/root');
    await tester.pumpAndSettle();

    expect(find.text('Safe Pop Root'), findsOneWidget);

    // Clicking safePop when canPop is false should navigate to home without throwing AssertionError
    await tester.tap(find.text('Safe Pop Root'));
    await tester.pumpAndSettle();

    expect(find.text('Home Page'), findsOneWidget);
  });
}
