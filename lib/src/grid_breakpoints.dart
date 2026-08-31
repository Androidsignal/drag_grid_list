/// Responsive column-count model keyed by viewport width.
///
/// Mirrors the classic mobile / tablet / desktop / web breakpoint tiers:
/// `< mobileMaxWidth` is mobile, `< tabletMaxWidth` is tablet, `<
/// desktopMaxWidth` is desktop, everything else is web/wide-desktop.
class GridBreakpoints {
  /// Creates a breakpoint model. All widths and column counts must be
  /// positive, and widths must be strictly increasing.
  const GridBreakpoints({
    this.mobileMaxWidth = 600,
    this.tabletMaxWidth = 1024,
    this.desktopMaxWidth = 1440,
    this.mobileColumns = 2,
    this.tabletColumns = 4,
    this.desktopColumns = 6,
    this.webColumns = 8,
  }) : assert(mobileMaxWidth > 0),
       assert(tabletMaxWidth > mobileMaxWidth),
       assert(desktopMaxWidth > tabletMaxWidth),
       assert(mobileColumns > 0),
       assert(tabletColumns > 0),
       assert(desktopColumns > 0),
       assert(webColumns > 0);

  /// Upper width bound (exclusive) of the mobile tier.
  final double mobileMaxWidth;

  /// Upper width bound (exclusive) of the tablet tier.
  final double tabletMaxWidth;

  /// Upper width bound (exclusive) of the desktop tier.
  final double desktopMaxWidth;

  /// Column count used below [mobileMaxWidth].
  final int mobileColumns;

  /// Column count used between [mobileMaxWidth] and [tabletMaxWidth].
  final int tabletColumns;

  /// Column count used between [tabletMaxWidth] and [desktopMaxWidth].
  final int desktopColumns;

  /// Column count used at or above [desktopMaxWidth].
  final int webColumns;

  /// The library default: mobile < 600, tablet < 1024, desktop < 1440,
  /// web >= 1440.
  static const GridBreakpoints defaultBreakpoints = GridBreakpoints();

  /// Resolves the column count for a given viewport [width].
  int columnsForWidth(double width) {
    if (width < mobileMaxWidth) return mobileColumns;
    if (width < tabletMaxWidth) return tabletColumns;
    if (width < desktopMaxWidth) return desktopColumns;
    return webColumns;
  }
}
