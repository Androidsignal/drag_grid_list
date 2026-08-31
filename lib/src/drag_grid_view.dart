import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'drag_callbacks.dart';
import 'drag_controller.dart';
import 'drag_feedback.dart';
import 'drag_grid_delegate.dart';
import 'drag_item.dart';
import 'grid_breakpoints.dart';
import 'grid_state_widgets.dart';
import 'reorder_reflow.dart';

/// Keeps [child]'s Element alive (exempt from the lazy list/grid's normal
/// off-screen disposal) for as long as [active] is listened-to as `true`.
///
/// Without this, auto-scrolling a long list while dragging its first item
/// eventually scrolls that item's slot off-screen; the lazy sliver then
/// disposes its Element mid-drag, which silently stops `onDragUpdate`/
/// `onDragEnd` from firing (Flutter's `Draggable` only calls those while
/// its State is still mounted) — auto-scroll then never stops and the
/// drop callback never fires.
class _KeepDraggedAlive extends StatefulWidget {
  const _KeepDraggedAlive({required this.active, required this.child});

  final ValueListenable<bool> active;
  final Widget child;

  @override
  State<_KeepDraggedAlive> createState() => _KeepDraggedAliveState();
}

class _KeepDraggedAliveState extends State<_KeepDraggedAlive>
    with AutomaticKeepAliveClientMixin<_KeepDraggedAlive> {
  @override
  bool get wantKeepAlive => widget.active.value;

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_onActiveChanged);
  }

  @override
  void didUpdateWidget(covariant _KeepDraggedAlive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      oldWidget.active.removeListener(_onActiveChanged);
      widget.active.addListener(_onActiveChanged);
      _onActiveChanged();
    }
  }

  void _onActiveChanged() => updateKeepAlive();

  @override
  void dispose() {
    widget.active.removeListener(_onActiveChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Which axis arrangement a [DragGridList] renders as.
enum DragListLayout {
  /// Single-axis reorderable list.
  list,

  /// Responsive, multi-column reorderable grid.
  grid,
}

/// Shares one [DragController] between sibling [DragGridList] widgets so
/// items can be dragged from one list/grid into another.
///
/// Each child declares its own `groupId` and `acceptGroups`; this scope
/// only wires them to a common drag session.
///
/// ```dart
/// DragGroupScope(
///   children: [
///     DragGridList<Task>(groupId: 'todo', acceptGroups: {'todo', 'doing', 'done'}, ...),
///     DragGridList<Task>(groupId: 'doing', acceptGroups: {'todo', 'doing', 'done'}, ...),
///     DragGridList<Task>(groupId: 'done', acceptGroups: {'todo', 'doing', 'done'}, ...),
///   ],
/// )
/// ```
class DragGroupScope extends StatefulWidget {
  /// Creates a scope laying out [children] along [direction], each given
  /// equal space, separated by [spacing].
  const DragGroupScope({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.spacing = 16,
  });

  /// The sibling [DragGridList] widgets (or ancestors of them) sharing this
  /// scope's drag session.
  final List<Widget> children;

  /// Layout axis for [children]. Horizontal reads as side-by-side columns
  /// (e.g. a kanban board); vertical stacks them.
  final Axis direction;

  /// Spacing between [children].
  final double spacing;

  /// Returns the ambient [DragController] shared by this scope, or `null`
  /// if [context] isn't under a [DragGroupScope].
  static DragController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DragControllerScope>()
        ?.controller;
  }

  @override
  State<DragGroupScope> createState() => _DragGroupScopeState();
}

class _DragGroupScopeState extends State<DragGroupScope> {
  final DragController _controller = DragController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      if (i > 0) {
        spaced.add(
          SizedBox(
            width: widget.direction == Axis.horizontal ? widget.spacing : 0,
            height: widget.direction == Axis.vertical ? widget.spacing : 0,
          ),
        );
      }
      spaced.add(Expanded(child: widget.children[i]));
    }
    return _DragControllerScope(
      controller: _controller,
      child: widget.direction == Axis.horizontal
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: spaced)
          : Column(children: spaced),
    );
  }
}

class _DragControllerScope extends InheritedNotifier<DragController> {
  const _DragControllerScope({
    required DragController controller,
    required super.child,
  }) : super(notifier: controller);

  DragController get controller => notifier!;
}

/// One widget covering: plain reorderable list, responsive reorderable
/// grid, and drag-and-drop between groups/lists.
///
/// Long-press drag on mobile, mouse drag on desktop/web (auto-detected,
/// fully overridable). Lazy/builder-based for large datasets.
class DragGridList<T> extends StatefulWidget {
  /// Creates a [DragGridList].
  const DragGridList.builder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.layout = DragListLayout.list,
    this.scrollDirection = Axis.vertical,
    this.minColumnWidth,
    this.minColumns = 1,
    this.maxColumns = 12,
    this.breakpoints,
    this.itemSpacing = 8,
    this.rowSpacing = 8,
    this.padding = EdgeInsets.zero,
    this.itemExtent,
    this.childAspectRatio = 1.0,
    this.enableReorder = true,
    this.enableLongPressDrag,
    this.enableMouseDrag,
    this.longPressDelay = const Duration(milliseconds: 500),
    this.groupId = 'default',
    this.acceptGroups,
    this.keyOf,
    this.dragPreviewBuilder,
    this.dragPlaceholderBuilder,
    this.onDragStart,
    this.onDragEnd,
    this.onReorder,
    this.onItemsChanged,
    this.onMove,
    this.onDrop,
    this.isLoading = false,
    this.loadingBuilder,
    this.emptyBuilder,
    this.reorderAnimationDuration = const Duration(milliseconds: 180),
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.autoScrollEdgeSize = 64,
    this.autoScrollMaxVelocity = 800,
  });

  /// The items to render. Package wraps them internally; consumer owns
  /// mutation (via [onReorder]/[onMove]/[onDrop]).
  final List<T> items;

  /// Builds the visual for one item.
  final DragItemBuilder<T> itemBuilder;

  /// List or grid arrangement.
  final DragListLayout layout;

  /// Scroll axis. Grid mode scrolls along the cross axis of [breakpoints].
  final Axis scrollDirection;

  /// Minimum column width used to auto-derive column count in grid mode,
  /// when [breakpoints] isn't supplied.
  final double? minColumnWidth;

  /// Lower clamp on the resolved grid column count.
  final int minColumns;

  /// Upper clamp on the resolved grid column count.
  final int maxColumns;

  /// Explicit breakpoint tiers overriding [minColumnWidth] auto-fit, in
  /// grid mode.
  final GridBreakpoints? breakpoints;

  /// Spacing between items along the main axis (list mode) or cross axis
  /// (grid mode columns).
  final double itemSpacing;

  /// Spacing between grid rows. Unused in list mode.
  final double rowSpacing;

  /// Padding around the whole list/grid.
  final EdgeInsetsGeometry padding;

  /// Fixed item size along [scrollDirection], list mode only. `null` sizes
  /// items intrinsically.
  final double? itemExtent;

  /// Cell aspect ratio, grid mode only.
  final double childAspectRatio;

  /// Master switch for all drag interactions on this list.
  final bool enableReorder;

  /// Use long-press-to-drag (mobile-style). `null` auto-detects by
  /// platform; explicit value overrides auto-detection.
  final bool? enableLongPressDrag;

  /// Use immediate mouse-down drag (desktop/web-style). `null`
  /// auto-detects by platform; explicit value overrides auto-detection.
  final bool? enableMouseDrag;

  /// Delay before a long-press drag gesture is recognized.
  final Duration longPressDelay;

  /// This list's group identity for cross-group drops.
  final String groupId;

  /// Which group ids this list accepts drops from. Defaults to `{groupId}`
  /// (self only — enables same-list reordering, disallows cross-group).
  final Set<String>? acceptGroups;

  /// Derives a stable key per item. Strongly recommended: without it,
  /// identity falls back to index, which can misbehave across reorders.
  final DragKeyOf<T>? keyOf;

  /// Builds the floating preview under the pointer. Defaults to an
  /// elevated, slightly scaled copy of the item.
  final DragPreviewBuilder<T>? dragPreviewBuilder;

  /// Builds the widget left in the source slot while dragging. Defaults to
  /// a dashed, dimmed box the same size as the item.
  final DragPlaceholderBuilder<T>? dragPlaceholderBuilder;

  /// Fires when a drag gesture is recognized.
  final DragStartCallback<T>? onDragStart;

  /// Fires when a drag gesture ends, regardless of drop success.
  final DragItemEndCallback<T>? onDragEnd;

  /// Fires on a same-list position change. Consumer applies
  /// `oldIndex`/`newIndex` themselves (e.g. via [DragController.applyReorder]).
  final DragReorderCallback? onReorder;

  /// Fires on a same-list position change with the reorder already applied.
  /// Prefer this over [onReorder] — no index math on the call site, just
  /// replace [items] with the callback's list.
  final ItemsChangedCallback<T>? onItemsChanged;

  /// Fires on a cross-group move.
  final MoveCallback<T>? onMove;

  /// Fires after any successful drop (reorder or move) resolves. Single
  /// funnel point for persistence logic.
  final DropCallback<T>? onDrop;

  /// Shows [loadingBuilder] instead of content when `true`.
  final bool isLoading;

  /// Builder shown while [isLoading] is `true`. Defaults to a centered
  /// spinner.
  final DragLoadingBuilder? loadingBuilder;

  /// Builder shown when [items] is empty and [isLoading] is `false`.
  /// Defaults to a centered "No items" message. Remains a valid drop
  /// target so an empty group can receive a drop.
  final DragEmptyBuilder? emptyBuilder;

  /// Duration of the hover/reflow highlight animation.
  final Duration reorderAnimationDuration;

  /// Passthrough to the underlying `ListView.builder`/`GridView.builder`.
  final bool addAutomaticKeepAlives;

  /// Passthrough to the underlying `ListView.builder`/`GridView.builder`.
  final bool addRepaintBoundaries;

  /// Distance in px from the viewport's leading/trailing edge, within
  /// which dragging an item auto-scrolls the list/grid toward that edge.
  final double autoScrollEdgeSize;

  /// Auto-scroll speed in px/second at the very edge, ramping down to 0 at
  /// [autoScrollEdgeSize] away from it.
  final double autoScrollMaxVelocity;

  @override
  State<DragGridList<T>> createState() => _DragGridListState<T>();
}

class _DragGridListState<T> extends State<DragGridList<T>>
    with SingleTickerProviderStateMixin {
  DragController? _ownedController;
  DragController? _controller;
  bool _warnedKeyOf = false;

  // Per-item-identity GlobalKeys, cached across rebuilds so a reordered
  // item's ReorderReflow Element (and thus its remembered on-screen
  // position) moves with it instead of being torn down and rebuilt.
  final Map<Object, GlobalKey> _reflowKeys = {};

  GlobalKey _reflowKeyFor(Object id) =>
      _reflowKeys.putIfAbsent(id, GlobalKey.new);

  // Per-item "is this the one being dragged" flags backing
  // _KeepDraggedAlive, so an item's Element survives being auto-scrolled
  // off-screen mid-drag.
  final Map<Object, ValueNotifier<bool>> _activeDragFlags = {};

  ValueNotifier<bool> _activeDragFlagFor(Object id) =>
      _activeDragFlags.putIfAbsent(id, () => ValueNotifier(false));

  // Auto-scroll while dragging near an edge. Rides the ambient Scrollable
  // found via the dragged item's own context — no controller of our own,
  // so it doesn't disturb however the list/grid is already scrolled
  // (PrimaryScrollController, a consumer-supplied one, or none). The
  // ticker drives the scroll frame-by-frame for as long as the pointer
  // stays in the edge band.
  ScrollPosition? _autoScrollPosition;
  Ticker? _autoScrollTicker;
  double _autoScrollVelocity = 0;
  Duration _autoScrollLastTick = Duration.zero;

  Set<String> get _acceptGroups => widget.acceptGroups ?? {widget.groupId};

  bool get _useMouseDrag {
    if (widget.enableMouseDrag != null) return widget.enableMouseDrag!;
    if (widget.enableLongPressDrag != null) return !widget.enableLongPressDrag!;
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ambient = DragGroupScope.maybeControllerOf(context);
    _controller = ambient ?? (_ownedController ??= DragController());
  }

  @override
  void dispose() {
    _autoScrollTicker?.dispose();
    _ownedController?.dispose();
    for (final flag in _activeDragFlags.values) {
      flag.dispose();
    }
    super.dispose();
  }

  void _handleDragUpdate(BuildContext itemContext, Offset globalPosition) {
    final scrollable = Scrollable.maybeOf(
      itemContext,
      axis: widget.scrollDirection,
    );
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.attached || !box.hasSize) {
      _stopAutoScroll();
      return;
    }
    final local = box.globalToLocal(globalPosition);
    final vertical = widget.scrollDirection == Axis.vertical;
    final extent = vertical ? box.size.height : box.size.width;
    final pos = vertical ? local.dy : local.dx;
    final edge = widget.autoScrollEdgeSize;

    double velocity = 0;
    if (edge > 0) {
      if (pos < edge) {
        final t = 1 - (pos.clamp(0, edge) / edge);
        velocity = -widget.autoScrollMaxVelocity * t;
      } else if (pos > extent - edge) {
        final t = 1 - ((extent - pos).clamp(0, edge) / edge);
        velocity = widget.autoScrollMaxVelocity * t;
      }
    }

    _autoScrollVelocity = velocity;
    if (velocity != 0) {
      _autoScrollPosition = scrollable.position;
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    // SingleTickerProviderStateMixin only ever vends one ticker per State,
    // so it's created lazily once and reused (stop/start) for the rest of
    // this widget's lifetime, rather than disposed and recreated every
    // time the pointer enters/leaves the edge band.
    final ticker = _autoScrollTicker ??= createTicker(_onAutoScrollTick);
    if (ticker.isActive) return;
    _autoScrollLastTick = Duration.zero;
    ticker.start();
  }

  void _onAutoScrollTick(Duration elapsed) {
    final dt = _autoScrollLastTick == Duration.zero
        ? Duration.zero
        : elapsed - _autoScrollLastTick;
    _autoScrollLastTick = elapsed;
    final position = _autoScrollPosition;
    if (_autoScrollVelocity == 0 || position == null || !position.hasPixels) {
      return;
    }
    final delta =
        _autoScrollVelocity * dt.inMicroseconds / Duration.microsecondsPerSecond;
    final newOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (newOffset != position.pixels) {
      position.jumpTo(newOffset);
    }
  }

  void _stopAutoScroll() {
    _autoScrollVelocity = 0;
    _autoScrollPosition = null;
    _autoScrollTicker?.stop();
  }

  Object _idForIndex(int index) {
    final data = widget.items[index];
    if (widget.keyOf != null) return widget.keyOf!(data);
    if (kDebugMode && !_warnedKeyOf) {
      _warnedKeyOf = true;
      debugPrint(
        'DragGridList("${widget.groupId}"): no keyOf supplied; falling back '
        'to index-based keys. Supply keyOf for stable identity across '
        'reorders and moves.',
      );
    }
    return '${widget.groupId}_$index';
  }

  void _handleDrop(DragItem<Object?> data, int targetIndex) {
    _controller!.clearHover();
    if (data.groupId == widget.groupId) {
      final adjusted = DragController.adjustReorderIndex(
        oldIndex: data.sourceIndex,
        newIndex: targetIndex,
      );
      if (DragController.isNoopReorder(
        oldIndex: data.sourceIndex,
        newIndex: adjusted,
      )) {
        return;
      }
      widget.onReorder?.call(data.sourceIndex, targetIndex);
      if (widget.onItemsChanged != null) {
        widget.onItemsChanged!(
          DragController.applyReorder(
            items: widget.items,
            oldIndex: data.sourceIndex,
            newIndex: targetIndex,
          ),
        );
      }
      widget.onDrop?.call(data.data as T, widget.groupId, adjusted);
    } else {
      widget.onMove?.call(
        data.data as T,
        data.groupId,
        widget.groupId,
        targetIndex,
      );
      widget.onDrop?.call(data.data as T, widget.groupId, targetIndex);
    }
  }

  Widget _buildSlot(BuildContext context, int index) {
    final item = widget.items[index];
    final id = _idForIndex(index);
    final itemKey = ValueKey(id);
    final dragItem = DragItem<T>(
      data: item,
      groupId: widget.groupId,
      itemKey: itemKey,
      sourceIndex: index,
    );
    final erasedItem = dragItem.cast<Object?>();
    final content = widget.itemBuilder(context, item, index);

    if (!widget.enableReorder) {
      return KeyedSubtree(key: itemKey, child: content);
    }

    final activeDragFlag = _activeDragFlagFor(id);

    void handleStarted() {
      _controller!.startDrag(erasedItem);
      activeDragFlag.value = true;
      widget.onDragStart?.call(item, index);
    }

    void handleEnded(DraggableDetails details) {
      activeDragFlag.value = false;
      widget.onDragEnd?.call(item, index);
      _controller!.endDrag();
      _stopAutoScroll();
    }

    // The feedback/placeholder overlay renders in an unbounded Overlay
    // Stack, so anything that needs a bounded width to lay out (e.g.
    // ListTile) crashes without an explicit size. Read the slot's own
    // constraints here and lock the defaults to them.
    final slot = LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : null;
        final slotHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;

        final placeholder =
            widget.dragPlaceholderBuilder?.call(context, item) ??
            DefaultDragPlaceholder(width: slotWidth, height: slotHeight);
        final preview =
            widget.dragPreviewBuilder?.call(context, item) ??
            DefaultDragPreview(
              width: slotWidth,
              height: slotHeight,
              child: content,
            );

        final Widget draggableChild = _useMouseDrag
            ? Draggable<DragItem<Object?>>(
                data: erasedItem,
                feedback: Material(color: Colors.transparent, child: preview),
                childWhenDragging: placeholder,
                onDragStarted: handleStarted,
                onDragUpdate: (details) =>
                    _handleDragUpdate(context, details.globalPosition),
                onDragEnd: handleEnded,
                child: content,
              )
            : LongPressDraggable<DragItem<Object?>>(
                data: erasedItem,
                delay: widget.longPressDelay,
                feedback: Material(color: Colors.transparent, child: preview),
                childWhenDragging: placeholder,
                onDragStarted: handleStarted,
                onDragUpdate: (details) =>
                    _handleDragUpdate(context, details.globalPosition),
                onDragEnd: handleEnded,
                child: content,
              );

        return DragTarget<DragItem<Object?>>(
          onWillAcceptWithDetails: (details) {
            final accepted = _acceptGroups.contains(details.data.groupId);
            if (accepted) _controller!.updateHover(widget.groupId, index);
            return accepted;
          },
          onLeave: (_) {
            if (_controller!.hoverGroupId == widget.groupId &&
                _controller!.hoverIndex == index) {
              _controller!.clearHover();
            }
          },
          onAcceptWithDetails: (details) {
            // Dropping directly onto a slot means "land in that slot's
            // spot." For a downward same-list move that raw target needs
            // to be one past the hovered slot: adjustReorderIndex/
            // applyReorder (mirroring ReorderableListView's contract)
            // subtract one to account for the shift caused by removing
            // the dragged item first. Without the +1 here, every downward
            // drop lands one slot short — and dropping on the very next
            // neighbor resolves to a no-op, snapping the item back.
            final data = details.data;
            final sameGroup = data.groupId == widget.groupId;
            final targetIndex = sameGroup && data.sourceIndex < index
                ? index + 1
                : index;
            _handleDrop(data, targetIndex);
          },
          builder: (context, candidateData, rejectedData) {
            // draggableChild must be a direct Stack child, not wrapped by
            // AnimatedContainer/AnimatedBuilder — nesting the live
            // Draggable inside an implicitly-animated ancestor silently
            // breaks its onDragUpdate delivery mid-drag (Flutter/Draggable
            // + ImplicitlyAnimatedWidget interaction). The hover border is
            // a separate, non-hit-testable overlay drawn on top instead.
            return Stack(
              children: [
                draggableChild,
                if (rejectedData.isNotEmpty)
                  const Positioned.fill(child: DragRejectOverlay()),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller!,
                      builder: (context, _) {
                        final isHoverTarget =
                            _controller!.hoverGroupId == widget.groupId &&
                            _controller!.hoverIndex == index;
                        return AnimatedContainer(
                          duration: widget.reorderAnimationDuration,
                          decoration: isHoverTarget
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return _KeepDraggedAlive(
      active: activeDragFlag,
      child: ReorderReflow(
        key: _reflowKeyFor(id),
        duration: widget.reorderAnimationDuration,
        child: KeyedSubtree(key: itemKey, child: slot),
      ),
    );
  }

  Widget _buildTrailingDropZone() {
    if (!widget.enableReorder) return const SizedBox.shrink();
    final targetIndex = widget.items.length;
    return DragTarget<DragItem<Object?>>(
      onWillAcceptWithDetails: (details) {
        final accepted = _acceptGroups.contains(details.data.groupId);
        if (accepted) _controller!.updateHover(widget.groupId, targetIndex);
        return accepted;
      },
      onLeave: (_) {
        if (_controller!.hoverGroupId == widget.groupId &&
            _controller!.hoverIndex == targetIndex) {
          _controller!.clearHover();
        }
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data, targetIndex),
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            final isHoverTarget =
                _controller!.hoverGroupId == widget.groupId &&
                _controller!.hoverIndex == targetIndex;
            return AnimatedContainer(
              duration: widget.reorderAnimationDuration,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
              decoration: isHoverTarget
                  ? BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final builder = widget.emptyBuilder ?? defaultDragEmptyBuilder;
    if (!widget.enableReorder) return builder(context);
    return DragTarget<DragItem<Object?>>(
      onWillAcceptWithDetails: (details) =>
          _acceptGroups.contains(details.data.groupId),
      onAcceptWithDetails: (details) => _handleDrop(details.data, 0),
      builder: (context, candidateData, rejectedData) => builder(context),
    );
  }

  Widget _wrapExtent(Widget slot) {
    if (widget.itemExtent == null) return slot;
    final vertical = widget.scrollDirection == Axis.vertical;
    return SizedBox(
      width: vertical ? null : widget.itemExtent,
      height: vertical ? widget.itemExtent : null,
      child: slot,
    );
  }

  Widget _buildList(BuildContext context) {
    final vertical = widget.scrollDirection == Axis.vertical;
    final itemCount = widget.items.length + 1;
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == widget.items.length) return _buildTrailingDropZone();
        final slot = _wrapExtent(_buildSlot(context, index));
        return Padding(
          padding: EdgeInsets.only(
            bottom: vertical ? widget.itemSpacing : 0,
            right: vertical ? 0 : widget.itemSpacing,
          ),
          child: slot,
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = DragGridDelegate.columnCountForWidth(
          width: constraints.maxWidth,
          minColumnWidth: widget.minColumnWidth,
          minColumns: widget.minColumns,
          maxColumns: widget.maxColumns,
          breakpoints: widget.breakpoints,
          spacing: widget.itemSpacing,
        );
        return GridView.builder(
          scrollDirection: widget.scrollDirection,
          padding: widget.padding,
          addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
          addRepaintBoundaries: widget.addRepaintBoundaries,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: widget.rowSpacing,
            crossAxisSpacing: widget.itemSpacing,
            childAspectRatio: widget.childAspectRatio,
          ),
          itemCount: widget.items.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.items.length) {
              return _buildTrailingDropZone();
            }
            return _buildSlot(context, index);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return (widget.loadingBuilder ?? defaultDragLoadingBuilder)(context);
    }
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }
    if (widget.enableReorder) {
      // Drop reflow keys for ids no longer present, so removed items don't
      // pin a GlobalKey (and its ReorderReflow State) in memory forever.
      final currentIds = {
        for (var i = 0; i < widget.items.length; i++) _idForIndex(i),
      };
      _reflowKeys.removeWhere((id, _) => !currentIds.contains(id));
      _activeDragFlags.removeWhere((id, flag) {
        final stale = !currentIds.contains(id);
        if (stale) flag.dispose();
        return stale;
      });
    }
    return widget.layout == DragListLayout.grid
        ? _buildGrid(context)
        : _buildList(context);
  }
}
