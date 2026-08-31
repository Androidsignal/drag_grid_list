import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragController.adjustReorderIndex', () {
    test('moving down shifts insertion index left by one', () {
      expect(DragController.adjustReorderIndex(oldIndex: 0, newIndex: 3), 2);
    });

    test('moving up keeps raw insertion index', () {
      expect(DragController.adjustReorderIndex(oldIndex: 3, newIndex: 0), 0);
    });

    test('moving to same spot is a no-op', () {
      final adjusted = DragController.adjustReorderIndex(
        oldIndex: 2,
        newIndex: 2,
      );
      expect(
        DragController.isNoopReorder(oldIndex: 2, newIndex: adjusted),
        isTrue,
      );
    });

    test(
      'dropping right after itself (newIndex = oldIndex + 1) is a no-op',
      () {
        final adjusted = DragController.adjustReorderIndex(
          oldIndex: 2,
          newIndex: 3,
        );
        expect(adjusted, 2);
        expect(
          DragController.isNoopReorder(oldIndex: 2, newIndex: adjusted),
          isTrue,
        );
      },
    );
  });

  group('DragController.applyReorder', () {
    test('moves item down the list', () {
      final result = DragController.applyReorder<String>(
        items: ['a', 'b', 'c', 'd'],
        oldIndex: 0,
        newIndex: 3,
      );
      expect(result, ['b', 'c', 'a', 'd']);
    });

    test('moves item up the list', () {
      final result = DragController.applyReorder<String>(
        items: ['a', 'b', 'c', 'd'],
        oldIndex: 3,
        newIndex: 0,
      );
      expect(result, ['d', 'a', 'b', 'c']);
    });

    test('moving one slot down effectively stays put', () {
      final result = DragController.applyReorder<String>(
        items: ['a', 'b', 'c'],
        oldIndex: 0,
        newIndex: 1,
      );
      expect(result, ['a', 'b', 'c']);
    });
  });

  group('DragController.applyMove', () {
    test('moves item from source list to target list at index', () {
      final source = ['a', 'b', 'c'];
      final target = ['x', 'y'];
      DragController.applyMove<String>(
        source: source,
        target: target,
        sourceIndex: 1,
        targetIndex: 1,
      );
      expect(source, ['a', 'c']);
      expect(target, ['x', 'b', 'y']);
    });

    test('clamps target index to target list bounds', () {
      final source = ['a'];
      final target = ['x', 'y'];
      DragController.applyMove<String>(
        source: source,
        target: target,
        sourceIndex: 0,
        targetIndex: 99,
      );
      expect(source, isEmpty);
      expect(target, ['x', 'y', 'a']);
    });
  });

  group('DragController session/hover state', () {
    test('startDrag sets session and notifies listeners', () {
      final controller = DragController();
      var notified = 0;
      controller.addListener(() => notified++);

      const item = DragItem<Object?>(
        data: 'payload',
        groupId: 'todo',
        itemKey: ValueKey('k1'),
        sourceIndex: 0,
      );
      controller.startDrag(item);

      expect(controller.session?.item.data, 'payload');
      expect(notified, 1);
    });

    test('updateHover dedupes repeated same-value calls', () {
      final controller = DragController();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.updateHover('todo', 2);
      controller.updateHover('todo', 2);
      controller.updateHover('todo', 3);

      expect(controller.hoverGroupId, 'todo');
      expect(controller.hoverIndex, 3);
      expect(notified, 2);
    });

    test('endDrag clears session and hover', () {
      final controller = DragController();
      const item = DragItem<Object?>(
        data: 1,
        groupId: 'g',
        itemKey: ValueKey('k'),
        sourceIndex: 0,
      );
      controller.startDrag(item);
      controller.updateHover('g', 1);

      controller.endDrag();

      expect(controller.session, isNull);
      expect(controller.hoverGroupId, isNull);
      expect(controller.hoverIndex, isNull);
    });
  });
}
