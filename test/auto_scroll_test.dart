import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double height = 400, double width = 400}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(height: height, width: width, child: child),
    ),
  );
}

void main() {
  testWidgets(
    'dragging near the bottom edge auto-scrolls the list',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          DragGridList<int>.builder(
            items: List.generate(30, (i) => i),
            itemExtent: 60,
            enableMouseDrag: false,
            enableLongPressDrag: true,
            longPressDelay: const Duration(milliseconds: 150),
            keyOf: (item) => ValueKey(item),
            itemBuilder: (context, item, index) =>
                SizedBox(height: 60, child: Text('Item $item')),
          ),
          height: 800,
        ),
      );

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 0);

      final startPos = tester.getCenter(find.text('Item 0'));
      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 200));

      // Drag toward the bottom in small, realistic increments (mirrors a
      // real finger drag) and hold there.
      for (var y = startPos.dy; y < 780; y += 20) {
        await gesture.moveTo(Offset(200, y));
        await tester.pump(const Duration(milliseconds: 16));
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(scrollable.position.pixels, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'dragging near the bottom edge auto-scrolls the grid',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          DragGridList<int>.builder(
            items: List.generate(20, (i) => i),
            layout: DragListLayout.grid,
            minColumnWidth: 120,
            childAspectRatio: 1,
            enableMouseDrag: false,
            enableLongPressDrag: true,
            longPressDelay: const Duration(milliseconds: 150),
            keyOf: (item) => ValueKey(item),
            itemBuilder: (context, item, index) =>
                Container(color: Colors.blue, child: Text('Item $item')),
          ),
          height: 800,
        ),
      );

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 0);

      final startPos = tester.getCenter(find.text('Item 0'));
      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 200));

      for (var y = startPos.dy; y < 780; y += 20) {
        await gesture.moveTo(Offset(200, y));
        await tester.pump(const Duration(milliseconds: 16));
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(scrollable.position.pixels, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
