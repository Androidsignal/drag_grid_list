import 'package:flutter/foundation.dart';

import 'drag_item.dart';

/// The currently active drag gesture, shared by every [DragGridList] under
/// the same [DragGroupScope] (or held privately by a standalone list).
@immutable
class DragSession {
  /// Creates a drag session snapshot.
  const DragSession({required this.item});

  /// The item being dragged, type-erased to `Object?` so it can cross
  /// generic-instantiation boundaries between sibling lists.
  final DragItem<Object?> item;
}

/// Owns the active drag session and current hover target for one drag
/// gesture, and provides the pure index-math helpers used to resolve a
/// drop into a reorder or a cross-group move.
///
/// A single [DragGridList] creates its own private controller when it is
/// not wrapped in a [DragGroupScope]; scoped lists share one controller so
/// items can drag between them.
class DragController extends ChangeNotifier {
  DragSession? _session;
  String? _hoverGroupId;
  int? _hoverIndex;

  /// The in-flight drag session, or `null` when nothing is being dragged.
  DragSession? get session => _session;

  /// Group id of the [DragGridList] currently under the pointer, if any.
  String? get hoverGroupId => _hoverGroupId;

  /// Insertion index within [hoverGroupId] currently under the pointer.
  int? get hoverIndex => _hoverIndex;

  /// Begins a drag session for [item].
  void startDrag(DragItem<Object?> item) {
    _session = DragSession(item: item);
    notifyListeners();
  }

  /// Updates the current hover target as the pointer moves over a
  /// candidate drop slot.
  void updateHover(String groupId, int index) {
    if (_hoverGroupId == groupId && _hoverIndex == index) return;
    _hoverGroupId = groupId;
    _hoverIndex = index;
    notifyListeners();
  }

  /// Clears the hover target, e.g. when the pointer leaves all drop zones.
  void clearHover() {
    if (_hoverGroupId == null && _hoverIndex == null) return;
    _hoverGroupId = null;
    _hoverIndex = null;
    notifyListeners();
  }

  /// Ends the drag session, dropped or cancelled.
  void endDrag() {
    _session = null;
    _hoverGroupId = null;
    _hoverIndex = null;
    notifyListeners();
  }

  /// Adjusts a raw drop [newIndex] into [ReorderableListView]-compatible
  /// semantics: both [oldIndex] and the returned index refer to positions
  /// in the list *before* the item is removed.
  ///
  /// When dragging downward, removing the item first shifts everything
  /// after it left by one, so the effective insertion index is one less
  /// than the raw drop index.
  static int adjustReorderIndex({
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < newIndex) return newIndex - 1;
    return newIndex;
  }

  /// Whether a reorder from [oldIndex] to [newIndex] (already adjusted via
  /// [adjustReorderIndex]) is a no-op.
  static bool isNoopReorder({required int oldIndex, required int newIndex}) =>
      oldIndex == newIndex;

  /// Applies a same-list reorder to [items], returning a new list.
  ///
  /// [newIndex] is the raw (pre-adjustment) drop index, matching the
  /// contract of [onReorder] callers such as [ReorderableListView].
  static List<T> applyReorder<T>({
    required List<T> items,
    required int oldIndex,
    required int newIndex,
  }) {
    final adjusted = adjustReorderIndex(oldIndex: oldIndex, newIndex: newIndex);
    final result = List<T>.of(items);
    final moved = result.removeAt(oldIndex);
    result.insert(adjusted, moved);
    return result;
  }

  /// Applies a cross-group move: removes [item] from [source] at
  /// [sourceIndex] and inserts it into [target] at [targetIndex].
  ///
  /// [source] and [target] must be distinct lists (different groups); for
  /// same-list moves use [applyReorder] instead.
  static void applyMove<T>({
    required List<T> source,
    required List<T> target,
    required int sourceIndex,
    required int targetIndex,
  }) {
    final item = source.removeAt(sourceIndex);
    final clampedIndex = targetIndex.clamp(0, target.length);
    target.insert(clampedIndex, item);
  }
}
