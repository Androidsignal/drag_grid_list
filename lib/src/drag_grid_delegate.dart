import 'grid_breakpoints.dart';

/// Resolves how many grid columns to render for a given viewport width.
///
/// Resolution order:
/// 1. If [breakpoints] is supplied, use its tiered column counts.
/// 2. Else if [minColumnWidth] is supplied, derive column count from
///    `width / minColumnWidth` (auto-fit, like CSS `repeat(auto-fit, minmax())`).
/// 3. Else fall back to [GridBreakpoints.defaultBreakpoints].
///
/// The result is always clamped to `[minColumns, maxColumns]`.
class DragGridDelegate {
  const DragGridDelegate._();

  /// Computes the column count for [width].
  static int columnCountForWidth({
    required double width,
    double? minColumnWidth,
    int minColumns = 1,
    int maxColumns = 12,
    GridBreakpoints? breakpoints,
    double spacing = 0,
  }) {
    assert(minColumns > 0);
    assert(maxColumns >= minColumns);

    int columns;
    if (breakpoints != null) {
      columns = breakpoints.columnsForWidth(width);
    } else if (minColumnWidth != null && minColumnWidth > 0 && width > 0) {
      columns = ((width + spacing) / (minColumnWidth + spacing)).floor();
    } else {
      columns = GridBreakpoints.defaultBreakpoints.columnsForWidth(width);
    }

    if (columns < minColumns) columns = minColumns;
    if (columns > maxColumns) columns = maxColumns;
    return columns;
  }
}
