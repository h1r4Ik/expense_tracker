import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:expense_tracker/ui/widgets/common/top_notification.dart';

void main() {
  testWidgets('TopNotificationService displays notification at top with message and title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TopNotificationService.show(
                    context: context,
                    title: 'Flatmates Ledger',
                    message: 'Alex added "Groceries" (₹450.00)',
                    type: TopNotificationType.info,
                    icon: LucideIcons.receipt,
                  );
                },
                child: const Text('Show Notification'),
              );
            },
          ),
        ),
      ),
    );

    // Initial state: no notification
    expect(find.text('Flatmates Ledger'), findsNothing);
    expect(find.text('Alex added "Groceries" (₹450.00)'), findsNothing);

    // Tap to show
    await tester.tap(find.text('Show Notification'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 350)); // Complete slide-in animation

    expect(find.text('Flatmates Ledger'), findsOneWidget);
    expect(find.text('Alex added "Groceries" (₹450.00)'), findsOneWidget);

    // Verify it is positioned near top of screen
    final notificationFinder = find.byKey(const Key('top_notification_dismissible'));
    expect(notificationFinder, findsOneWidget);
    final topOffset = tester.getTopLeft(notificationFinder).dy;
    expect(topOffset, lessThan(100.0));

    // Can be dismissed manually
    TopNotificationService.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Flatmates Ledger'), findsNothing);
  });

  testWidgets('TopNotificationService dismisses via upward swipe gesture',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TopNotificationService.show(
                    context: context,
                    title: 'Trip Ledger',
                    message: 'Sarah added "Dinner" (₹1,200.00)',
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Trip Ledger'), findsOneWidget);

    // Swipe up on the notification
    final dismissibleFinder = find.byKey(const Key('top_notification_dismissible'));
    await tester.drag(dismissibleFinder, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Trip Ledger'), findsNothing);
  });
}
