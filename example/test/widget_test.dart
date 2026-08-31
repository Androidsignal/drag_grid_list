import 'package:drag_grid_list_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app boots and shows the first demo page', (
    tester,
  ) async {
    await tester.pumpWidget(const DragGridListExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('1. Basic list'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing); // closed by default
  });

  testWidgets('drawer navigates to the cross-group demo page', (tester) async {
    await tester.pumpWidget(const DragGridListExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5. Cross-group drag'));
    await tester.pumpAndSettle();

    expect(find.text('To do (4)'), findsOneWidget);
  });
}
