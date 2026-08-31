import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty list renders emptyBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DragGridList<String>.builder(
            items: const [],
            itemBuilder: (context, item, index) => Text(item),
            emptyBuilder: (context) => const Text('nothing here'),
          ),
        ),
      ),
    );

    expect(find.text('nothing here'), findsOneWidget);
  });

  testWidgets('empty list without emptyBuilder falls back to default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DragGridList<String>.builder(
            items: const [],
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      ),
    );

    expect(find.text('No items'), findsOneWidget);
  });

  testWidgets('empty group still accepts a drop from a sibling group', (
    tester,
  ) async {
    final moves = <List<Object?>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: DragGroupScope(
              children: [
                DragGridList<String>.builder(
                  items: const ['a1'],
                  groupId: 'listA',
                  acceptGroups: const {'listA'},
                  itemExtent: 60,
                  enableMouseDrag: true,
                  enableLongPressDrag: false,
                  keyOf: (item) => ValueKey(item),
                  itemBuilder: (context, item, index) =>
                      SizedBox(height: 60, child: Text(item)),
                ),
                DragGridList<String>.builder(
                  items: const [],
                  groupId: 'listB',
                  acceptGroups: const {'listA', 'listB'},
                  itemBuilder: (context, item, index) => Text(item),
                  emptyBuilder: (context) => const Text('drop here'),
                  onMove: (item, from, to, index) =>
                      moves.add([item, from, to, index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('drop here'), findsOneWidget);

    final startPos = tester.getCenter(find.text('a1'));
    final targetPos = tester.getCenter(find.text('drop here'));

    final gesture = await tester.startGesture(startPos);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(targetPos);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(moves, isNotEmpty);
    expect(moves.first[1], 'listA');
    expect(moves.first[2], 'listB');
    expect(moves.first[3], 0);
  });
}
