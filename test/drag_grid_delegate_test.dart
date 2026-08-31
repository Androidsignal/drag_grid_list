import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragGridDelegate.columnCountForWidth', () {
    test('uses default breakpoints when nothing else supplied', () {
      expect(DragGridDelegate.columnCountForWidth(width: 320), 2); // mobile
      expect(DragGridDelegate.columnCountForWidth(width: 700), 4); // tablet
      expect(DragGridDelegate.columnCountForWidth(width: 1200), 6); // desktop
      expect(DragGridDelegate.columnCountForWidth(width: 1600), 8); // web
    });

    test('uses explicit breakpoints when supplied', () {
      const breakpoints = GridBreakpoints(
        mobileMaxWidth: 500,
        tabletMaxWidth: 800,
        desktopMaxWidth: 1100,
        mobileColumns: 1,
        tabletColumns: 3,
        desktopColumns: 5,
        webColumns: 10,
      );
      expect(
        DragGridDelegate.columnCountForWidth(
          width: 300,
          breakpoints: breakpoints,
        ),
        1,
      );
      expect(
        DragGridDelegate.columnCountForWidth(
          width: 900,
          breakpoints: breakpoints,
        ),
        5,
      );
      expect(
        DragGridDelegate.columnCountForWidth(
          width: 2000,
          breakpoints: breakpoints,
        ),
        10,
      );
    });

    test(
      'derives column count from minColumnWidth when no breakpoints given',
      () {
        expect(
          DragGridDelegate.columnCountForWidth(
            width: 1000,
            minColumnWidth: 200,
            maxColumns: 20,
          ),
          5,
        );
        expect(
          DragGridDelegate.columnCountForWidth(
            width: 1000,
            minColumnWidth: 240,
            spacing: 10,
            maxColumns: 20,
          ),
          4, // (1000 + 10) / (240 + 10) = 4.04 -> floor 4
        );
      },
    );

    test('clamps to minColumns/maxColumns', () {
      expect(
        DragGridDelegate.columnCountForWidth(
          width: 3000,
          minColumnWidth: 50,
          maxColumns: 6,
        ),
        6,
      );
      expect(
        DragGridDelegate.columnCountForWidth(
          width: 50,
          minColumnWidth: 500,
          minColumns: 2,
        ),
        2,
      );
    });
  });
}
