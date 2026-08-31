import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double width = 400, double height = 400}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

void main() {
  group('DragGridList list mode', () {
    testWidgets('renders items', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DragGridList<String>.builder(
            items: const ['a', 'b', 'c'],
            itemExtent: 60,
            itemBuilder: (context, item, index) =>
                Container(key: ValueKey(item), child: Text('Item $item')),
          ),
        ),
      );

      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('drag gesture triggers onDragStart and onReorder', (
      tester,
    ) async {
      final started = <int>[];
      final reordered = <List<int>>[];

      await tester.pumpWidget(
        _wrap(
          DragGridList<String>.builder(
            items: const ['a', 'b', 'c'],
            itemExtent: 80,
            enableMouseDrag: true,
            enableLongPressDrag: false,
            keyOf: (item) => ValueKey(item),
            itemBuilder: (context, item, index) => Container(
              height: 80,
              alignment: Alignment.center,
              child: Text('Item $item'),
            ),
            onDragStart: (item, index) => started.add(index),
            onReorder: (oldIndex, newIndex) =>
                reordered.add([oldIndex, newIndex]),
          ),
        ),
      );

      final startPos = tester.getCenter(find.text('Item a'));
      final targetPos = tester.getCenter(find.text('Item c'));

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos + const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(started, [0]);
      expect(reordered, isNotEmpty);
      expect(reordered.first[0], 0);
    });

    testWidgets('dragging an item onto its immediate next neighbor swaps them', (
      tester,
    ) async {
      List<String> items = ['a', 'b', 'c'];
      late StateSetter setState;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return DragGridList<String>.builder(
                items: items,
                itemExtent: 80,
                enableMouseDrag: true,
                enableLongPressDrag: false,
                keyOf: (item) => ValueKey(item),
                itemBuilder: (context, item, index) => Container(
                  height: 80,
                  alignment: Alignment.center,
                  child: Text('Item $item'),
                ),
                onItemsChanged: (next) => setState(() => items = next),
              );
            },
          ),
        ),
      );

      final startPos = tester.getCenter(find.text('Item a'));
      final targetPos = tester.getCenter(find.text('Item b'));

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(items, ['b', 'a', 'c']);
    });

    testWidgets('custom dragPreviewBuilder/dragPlaceholderBuilder are used', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DragGridList<String>.builder(
            items: const ['a', 'b'],
            itemExtent: 60,
            enableMouseDrag: true,
            enableLongPressDrag: false,
            itemBuilder: (context, item, index) =>
                SizedBox(height: 60, child: Text('Item $item')),
            dragPreviewBuilder: (context, item) =>
                Text('preview-$item', key: const Key('custom-preview')),
            dragPlaceholderBuilder: (context, item) =>
                Container(key: const Key('custom-placeholder')),
          ),
        ),
      );

      expect(find.byType(DefaultDragPreview), findsNothing);
      expect(find.byType(DefaultDragPlaceholder), findsNothing);

      final startPos = tester.getCenter(find.text('Item a'));
      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(startPos + const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('custom-placeholder')), findsOneWidget);
      expect(find.byKey(const Key('custom-preview')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('DragGridList grid mode', () {
    testWidgets('renders responsive column count and reacts to resize', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget buildAt(double width) => _wrap(
        DragGridList<int>.builder(
          items: List.generate(12, (i) => i),
          layout: DragListLayout.grid,
          breakpoints: const GridBreakpoints(
            mobileMaxWidth: 500,
            tabletMaxWidth: 900,
            desktopMaxWidth: 1300,
            mobileColumns: 2,
            tabletColumns: 4,
            desktopColumns: 6,
            webColumns: 8,
          ),
          itemBuilder: (context, item, index) =>
              Container(key: ValueKey(item), child: Text('Item $item')),
        ),
        width: width,
      );

      await tester.pumpWidget(buildAt(400));
      var gridView = tester.widget<GridView>(find.byType(GridView));
      var delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      await tester.pumpWidget(buildAt(1000));
      gridView = tester.widget<GridView>(find.byType(GridView));
      delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);
    });
  });
}
