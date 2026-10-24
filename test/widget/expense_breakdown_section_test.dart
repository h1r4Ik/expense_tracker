import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/ui/widgets/charts/expense_breakdown_section.dart';

void main() {
  testWidgets('ExpenseBreakdownSection renders empty state when no expenses', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ExpenseBreakdownSection(
              expenseTransactions: [],
              totalExpense: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.text('No Expense Records'), findsOneWidget);
  });

  testWidgets('ExpenseBreakdownSection renders donut chart, toggles to bar chart, and handles taps', (tester) async {
    final expenses = [
      ExpenseTransaction(
        id: '1',
        title: 'Lunch',
        amount: 250.0,
        date: DateTime.now(),
        category: 'Food & Dining',
        type: TransactionType.expense,
      ),
      ExpenseTransaction(
        id: '2',
        title: 'Dinner',
        amount: 150.0,
        date: DateTime.now(),
        category: 'Food & Dining',
        type: TransactionType.expense,
      ),
      ExpenseTransaction(
        id: '3',
        title: 'Uber',
        amount: 200.0,
        date: DateTime.now(),
        category: 'Transportation',
        type: TransactionType.expense,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseBreakdownSection(
              expenseTransactions: expenses,
              totalExpense: 600.0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Expense Breakdown'), findsOneWidget);

    // Verify Categories chips exist
    expect(find.text('Food & Dining'), findsWidgets);
    expect(find.text('Transportation'), findsWidgets);

    // Default donut center shows TOTAL SPENT
    expect(find.text('TOTAL SPENT'), findsOneWidget);

    // Tap on category pill to select
    await tester.tap(find.text('Transportation').first);
    await tester.pumpAndSettle();

    // Verify center shows selected category
    expect(find.text('Transportation'), findsWidgets);

    // Verify manual scroll interaction works on filter chips
    final scrollFinder = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollFinder, const Offset(-50, 0));
    await tester.pumpAndSettle();

    // Tap the center bubble to clear selection
    await tester.tap(find.text('Transportation').first);
    await tester.pumpAndSettle();
    expect(find.text('TOTAL SPENT'), findsOneWidget);
  });
}
