import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/main.dart';
import 'package:task_manager/services/task_store.dart';

void main() {
  testWidgets('Add, complete and delete a task', (WidgetTester tester) async {
    // Isolated store so the test never touches real user data.
    final store = TaskStore(
      fileName: 'test_widget_${DateTime.now().microsecondsSinceEpoch}.json',
    );
    addTearDown(store.deleteTestFile);

    await tester.pumpWidget(MyApp(store: store));

    // Initially no tasks.
    expect(find.text('No tasks yet.'), findsOneWidget);

    // Add a task.
    await tester.enterText(find.byType(TextField), 'Milch kaufen');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(const Duration(milliseconds: 300)); // flush scroll timer

    expect(find.text('Milch kaufen'), findsOneWidget);
    expect(find.text('No tasks yet.'), findsNothing);

    // Mark as done (second checkbox is the task's own checkbox,
    // the first one is "Select All").
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();

    final taskCheckbox = tester.widget<Checkbox>(find.byType(Checkbox).at(1));
    expect(taskCheckbox.value, isTrue);

    // Delete the task via "Delete All".
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Milch kaufen'), findsNothing);
    expect(find.text('No tasks yet.'), findsOneWidget);
  });
}