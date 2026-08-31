import 'package:flutter/foundation.dart';

/// Identity + accept-rules for one [DragGridList] participating in a
/// [DragGroupScope].
@immutable
class DragGroupInfo {
  /// Creates group info.
  const DragGroupInfo({required this.groupId, required this.acceptGroups});

  /// This list's own group id.
  final String groupId;

  /// Set of group ids this list accepts drops from (typically including
  /// its own [groupId] to allow same-list reordering).
  final Set<String> acceptGroups;

  /// Whether a drag item originating from [sourceGroupId] may be dropped
  /// onto this group.
  bool accepts(String sourceGroupId) => acceptGroups.contains(sourceGroupId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DragGroupInfo &&
          other.groupId == groupId &&
          setEquals(other.acceptGroups, acceptGroups));

  @override
  int get hashCode =>
      Object.hash(groupId, Object.hashAllUnordered(acceptGroups));
}
