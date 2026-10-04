import 'package:aicc/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty state shows a friendly title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications yet',
            message: 'Fee challans will show up here.',
          ),
        ),
      ),
    );

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });
}
