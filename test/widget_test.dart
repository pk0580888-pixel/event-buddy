import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:event_buddy/main.dart';

void main() {
  testWidgets('loads the authentication welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EventBuddyApp());

    expect(find.text('Event Buddy'), findsOneWidget);
    expect(find.text('CONNECT  •  CREATE  •  CELEBRATE'), findsOneWidget);
    expect(find.text('Student login'), findsOneWidget);
    expect(find.text('Admin login'), findsOneWidget);
    expect(find.text('Create a student account'), findsOneWidget);
  });

  testWidgets('opens student, admin and registration entry points', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EventBuddyApp());

    await tester.tap(find.text('Student login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin login'));
    await tester.pumpAndSettle();
    expect(find.text('Admin login'), findsOneWidget);
    expect(find.text('Sign in as admin'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    final registerButton = find.text('Create a student account');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();
    expect(find.text('Create student account'), findsOneWidget);
    expect(find.text('Student ID'), findsOneWidget);
  });
}
