import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';

void main() {
  testWidgets('HasibButton renders properly in bounded constraints', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: HasibButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
  });

  testWidgets('HasibButton renders without crashing in unbounded horizontal constraints (e.g. Row without Expanded)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              HasibButton(
                label: 'Unbounded Button',
                fullWidth: true, // should safely fallback when constraints.hasBoundedWidth is false
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Unbounded Button'), findsOneWidget);
  });
}
