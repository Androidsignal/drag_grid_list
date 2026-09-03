import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out [children] into [crossAxisCount] columns, placing each child in
/// whichever column has accumulated the least height so far
/// ("masonry"/Pinterest-style packing) instead of lockstep rows like
/// [GridView].
///
/// Column placement and each child's height are both resolved in a single
/// layout pass — no offstage pre-measure, no flicker — but that means every
/// child must be laid out for this widget to size itself. Unlike
/// `DragGridList`'s list/grid modes it isn't lazy; fine for moderate item
/// counts, prefer grid layout for very large datasets.
///
/// Sizes to a bounded incoming width and however tall the tallest resulting
/// column is; meant to sit inside a vertically-scrolling ancestor (e.g.
/// [SingleChildScrollView]), not the reverse.
class MasonryGrid extends MultiChildRenderObjectWidget {
  /// Creates a masonry layout of [children] across [crossAxisCount] columns.
  const MasonryGrid({
    super.key,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    required super.children,
  }) : assert(crossAxisCount > 0);

  /// Number of columns to pack children into.
  final int crossAxisCount;

  /// Vertical gap left below each child, within its column.
  final double mainAxisSpacing;

  /// Horizontal gap between columns.
  final double crossAxisSpacing;

  @override
  RenderMasonryGrid createRenderObject(BuildContext context) {
    return RenderMasonryGrid(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMasonryGrid renderObject,
  ) {
    renderObject
      ..crossAxisCount = crossAxisCount
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing;
  }
}

/// Parent data for children of [RenderMasonryGrid] — just an offset, same as
/// any other unaligned box container.
class MasonryGridParentData extends ContainerBoxParentData<RenderBox> {}

/// Render object backing [MasonryGrid]. See that class's doc for the
/// packing algorithm.
class RenderMasonryGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MasonryGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MasonryGridParentData> {
  /// Creates the render object. See [MasonryGrid] for field meanings.
  RenderMasonryGrid({
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
  })  : _crossAxisCount = crossAxisCount,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing;

  int _crossAxisCount;

  int get crossAxisCount => _crossAxisCount;

  set crossAxisCount(int value) {
    if (_crossAxisCount == value) return;
    _crossAxisCount = value;
    markNeedsLayout();
  }

  double _mainAxisSpacing;

  double get mainAxisSpacing => _mainAxisSpacing;

  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  double _crossAxisSpacing;

  double get crossAxisSpacing => _crossAxisSpacing;

  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MasonryGridParentData) {
      child.parentData = MasonryGridParentData();
    }
  }

  @override
  void performLayout() {
    final columns = crossAxisCount;
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final columnWidth = ((constraints.maxWidth - totalSpacing) / columns).clamp(0.0, double.infinity);
    final columnHeights = List<double>.filled(columns, 0);

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as MasonryGridParentData;

      var shortest = 0;
      for (var i = 1; i < columns; i++) {
        if (columnHeights[i] < columnHeights[shortest]) shortest = i;
      }

      child.layout(
        BoxConstraints.tightFor(width: columnWidth),
        parentUsesSize: true,
      );
      parentData.offset = Offset(
        shortest * (columnWidth + crossAxisSpacing),
        columnHeights[shortest],
      );
      columnHeights[shortest] += child.size.height + mainAxisSpacing;

      child = parentData.nextSibling;
    }

    final contentHeight = columnHeights.isEmpty
        ? 0.0
        : (columnHeights.reduce((a, b) => a > b ? a : b) - mainAxisSpacing).clamp(0.0, double.infinity);
    size = constraints.constrain(Size(constraints.maxWidth, contentHeight));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
