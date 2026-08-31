import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _board({
  required Set<String> acceptGroupsA,
  required Set<String> acceptGroupsB,
  required void Function(int, int) onReorderA,
  required void Function(String, String, String, int) onMoveA,
  required void Function(int, int) onReorderB,
  required void Function(String, String, String, int) onMoveB,
  required void Function(String, int) onDragEndA,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 400,
        child: DragGroupScope(
          children: [
            DragGridList<String>.builder(
              items: const ['a1', 'a2'],
              groupId: 'listA',
              acceptGroups: acceptGroupsA,
              itemExtent: 60,
              enableMouseDrag: true,
              enableLongPressDrag: false,
              keyOf: (item) => ValueKey(item),
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 60, child: Text(item)),
              onReorder: onReorderA,
              onMove: onMoveA,
              onDragEnd: onDragEndA,
            ),
            DragGridList<String>.builder(
              items: const ['b1'],
              groupId: 'listB',
              acceptGroups: acceptGroupsB,
              itemExtent: 60,
              enableMouseDrag: true,
              enableLongPressDrag: false,
              keyOf: (item) => ValueKey(item),
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 60, child: Text(item)),
              onReorder: onReorderB,
              onMove: onMoveB,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'dragging item from listA into listB fires onMove, not onReorder',
    (tester) async {
      final movesOnB = <List<Object?>>[];
      final reordersOnA = <List<int>>[];
      final reordersOnB = <List<int>>[];

      await tester.pumpWidget(
        _board(
          acceptGroupsA: {'listA'},
          acceptGroupsB: {'listA', 'listB'},
          onReorderA: (o, n) => reordersOnA.add([o, n]),
          onMoveA: (item, from, to, index) {},
          onReorderB: (o, n) => reordersOnB.add([o, n]),
          onMoveB: (item, from, to, index) =>
              movesOnB.add([item, from, to, index]),
          onDragEndA: (item, index) {},
        ),
      );

      final startPos = tester.getCenter(find.text('a1'));
      final targetPos = tester.getCenter(find.text('b1'));

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos + const Offset(0, 5));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(movesOnB, isNotEmpty);
      expect(movesOnB.first[1], 'listA'); // fromGroupId
      expect(movesOnB.first[2], 'listB'); // toGroupId
      expect(reordersOnA, isEmpty);
      expect(reordersOnB, isEmpty);
    },
  );

  testWidgets(
    'dropping onto a group not in acceptGroups snaps back, no callback fires',
    (tester) async {
      final movesOnB = <List<Object?>>[];
      final dragEnds = <String>[];

      await tester.pumpWidget(
        _board(
          acceptGroupsA: {'listA'},
          acceptGroupsB: {'listB'}, // does NOT accept listA
          onReorderA: (o, n) {},
          onMoveA: (item, from, to, index) {},
          onReorderB: (o, n) {},
          onMoveB: (item, from, to, index) =>
              movesOnB.add([item, from, to, index]),
          onDragEndA: (item, index) => dragEnds.add(item),
        ),
      );

      final startPos = tester.getCenter(find.text('a1'));
      final targetPos = tester.getCenter(find.text('b1'));

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetPos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(movesOnB, isEmpty);
      expect(dragEnds, ['a1']);
    },
  );
}
