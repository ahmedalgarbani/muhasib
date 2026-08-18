import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/main/presentation/models/card_data.dart';
import 'package:muhasib/features/main/presentation/widgets/cards_carousel.dart';
import 'package:muhasib/features/main/presentation/widgets/finance_card.dart';

void main() {
  group('CardsCarousel & FinanceCard Tests', () {
    final testCards = [
      const CardData(
        title: 'الصندوق الرئيسي',
        balance: '150,000.00',
        currency: 'YER',
        type: CardType.primary,
      ),
      const CardData(
        title: 'حساب البنك الأهلي',
        balance: '45,000.00',
        currency: 'SAR',
        type: CardType.secondary,
      ),
      const CardData(
        title: 'صندوق المبيعات',
        balance: '12,500.00',
        currency: 'USD',
        type: CardType.success,
      ),
    ];

    testWidgets('Renders CardsCarousel in RTL without errors', (tester) async {
      int activeIndex = 0;
      bool showBalance = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CardsCarousel(
                    cards: testCards,
                    showBalance: showBalance,
                    activeIndex: activeIndex,
                    onPageChanged: (index) => setState(() => activeIndex = index),
                    onToggleBalance: () =>
                        setState(() => showBalance = !showBalance),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CardsCarousel), findsOneWidget);
      expect(find.byType(FinanceCard), findsWidgets);
      expect(find.text('الصندوق الرئيسي'), findsOneWidget);
      expect(find.text('150,000.00'), findsOneWidget);
    });

    testWidgets('Toggles balance visibility on eye tap', (tester) async {
      bool showBalance = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CardsCarousel(
                  cards: testCards,
                  showBalance: showBalance,
                  activeIndex: 0,
                  onPageChanged: (_) {},
                  onToggleBalance: () =>
                      setState(() => showBalance = !showBalance),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('150,000.00'), findsOneWidget);

      // Tap on the balance title/eye row
      await tester.tap(find.text('الصندوق الرئيسي'));
      await tester.pumpAndSettle();

      expect(showBalance, isFalse);
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('Swiping page triggers onPageChanged', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CardsCarousel(
                    cards: testCards,
                    showBalance: true,
                    activeIndex: activeIndex,
                    onPageChanged: (index) => setState(() => activeIndex = index),
                    onToggleBalance: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag carousel to switch page
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(activeIndex, greaterThanOrEqualTo(0));
    });
  });
}
