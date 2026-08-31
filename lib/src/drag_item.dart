import 'package:flutter/foundation.dart';

/// Internal wrapper that carries a piece of consumer data through a drag
/// gesture, together with the identity needed to resolve reorder / move.
@immutable
class DragItem<T> {
  /// Creates a drag item wrapper.
  const DragItem({
    required this.data,
    required this.groupId,
    required this.itemKey,
    required this.sourceIndex,
  });

  /// The consumer-supplied payload.
  final T data;

  /// Id of the [DragGridList] group this item currently belongs to.
  final String groupId;

  /// Stable key identifying this item across rebuilds/moves.
  final Key itemKey;

  /// Index of this item in its source list at drag-start time.
  final int sourceIndex;

  /// Returns a copy of this item re-typed as [R], casting [data].
  ///
  /// Used when a drag session crosses widget boundaries with the same
  /// concrete data type but a different generic instantiation site.
  DragItem<R> cast<R>() => DragItem<R>(
    data: data as R,
    groupId: groupId,
    itemKey: itemKey,
    sourceIndex: sourceIndex,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DragItem<T> &&
          other.data == data &&
          other.groupId == groupId &&
          other.itemKey == itemKey &&
          other.sourceIndex == sourceIndex);

  @override
  int get hashCode => Object.hash(data, groupId, itemKey, sourceIndex);

  @override
  String toString() =>
      'DragItem(groupId: $groupId, sourceIndex: $sourceIndex, key: $itemKey)';
}
