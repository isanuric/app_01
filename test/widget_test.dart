import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_01/main.dart';

void main() {
  testWidgets('Add, complete and delete a task', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initially no tasks.
    expect(find.text('Noch keine Aufgaben.'), findsOneWidget);

    // Add a task.
    await tester.enterText(find.byType(TextField), 'Milch kaufen');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Milch kaufen'), findsOneWidget);
    expect(find.text('Noch keine Aufgaben.'), findsNothing);

    // Mark as done.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);

    // Delete the task.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Milch kaufen'), findsNothing);
    expect(find.text('Noch keine Aufgaben.'), findsOneWidget);
  });
}
