import 'package:flutter/widgets.dart';

/// Builds the widget for [item] at [index].
typedef DragItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// Builds the floating preview shown under the pointer while [item] drags.
typedef DragPreviewBuilder<T> = Widget Function(BuildContext context, T item);

/// Builds the widget left behind in the source slot while [item] drags.
typedef DragPlaceholderBuilder<T> = Widget Function(
  BuildContext context,
  T item,
);

/// Fires when a drag gesture on [item] at [index] is recognized.
typedef DragStartCallback<T> = void Function(T item, int index);

/// Fires when a drag gesture on [item] ends, whether or not it dropped
/// successfully. [index] is the item's index at drag-start time.
typedef DragItemEndCallback<T> = void Function(T item, int index);

/// Fires when an item moves position within the same list/group.
///
/// [oldIndex] / [newIndex] follow [ReorderableListView] semantics: both are
/// indices into the list *before* the move is applied.
typedef DragReorderCallback = void Function(int oldIndex, int newIndex);

/// Fires when [item] moves from one group to another.
typedef MoveCallback<T> = void Function(
  T item,
  String fromGroupId,
  String toGroupId,
  int toIndex,
);

/// Fires after any successful drop (reorder or cross-group move) resolves.
/// Single funnel point for persistence logic.
typedef DropCallback<T> = void Function(
  T item,
  String targetGroupId,
  int targetIndex,
);

/// Fires after a same-list reorder with the whole list already reordered.
///
/// Sugar over [DragReorderCallback]: the package applies
/// [DragController.applyReorder] internally so callers never touch
/// `oldIndex`/`newIndex` math themselves — just replace `items` with
/// [items] (e.g. `setState(() => _items = items)`).
typedef ItemsChangedCallback<T> = void Function(List<T> items);

/// Builds the widget shown while `isLoading` is true.
typedef DragLoadingBuilder = WidgetBuilder;

/// Builds the widget shown when the item list is empty.
typedef DragEmptyBuilder = WidgetBuilder;

/// Derives a stable [Key] for [item]. Prefer a real identifier (e.g. an id
/// field) over relying on the index-based fallback.
typedef DragKeyOf<T> = Key Function(T item);
