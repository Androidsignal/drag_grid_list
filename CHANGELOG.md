## 0.0.4

* **Metadata Improvements**: Added screenshots, topics, and an improved package description to `pubspec.yaml` for better visibility on pub.dev.
* **README Updates**: Added status badges (likes, points, popularity) and refined documentation.

## 0.0.3

* Fix: dragging an item collapsed its placeholder to 0×0 whenever the slot
  couldn't report a bounded height — always true for masonry cells (no
  fixed row height to measure against), and for list items without
  `itemExtent`. In masonry that 0-height placeholder shrunk the dragged
  item's column and violently reflowed every item below it for the whole
  drag. The default placeholder/preview now fall back to the item's last
  real laid-out size (tracked live, no `GlobalKey` needed) instead of
  collapsing.

* Add `DragListLayout.masonry` — responsive, reorderable Pinterest-style
  masonry layout. Cells keep their natural height and pack into whichever
  column is shortest so far, instead of grid mode's fixed
  `childAspectRatio` lockstep rows. Column count resolves the same way as
  grid mode (`minColumnWidth`/`breakpoints`, clamped to
  `minColumns`/`maxColumns`). Always scrolls vertically; not lazy (every
  item is built and laid out up front to pack it) — prefer grid mode for
  very large datasets.

## 0.0.2

* Fix: dropping an item onto its immediate next neighbor was a no-op —
  the drag snaps back to its original position instead of swapping.
  Every downward same-list drop landed one slot short of where it was
  dropped; only the adjacent case happened to land back on the source
  index. `DragGridList`'s per-slot drop target now passes the raw index
  `ReorderableListView`-style reorder math expects.

## 0.0.1

Initial release.
