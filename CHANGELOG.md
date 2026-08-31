## 0.0.1

Initial release.

* `DragGridList<T>.builder` — reorderable list (`DragListLayout.list`) and
  responsive reorderable grid (`DragListLayout.grid`) in one widget.
* Responsive grid columns via explicit `GridBreakpoints` or auto-fit
  `minColumnWidth`, clamped to `minColumns`/`maxColumns`.
* Long-press drag (mobile) and mouse drag (desktop/web), auto-detected by
  platform and fully overridable per list.
* `DragGroupScope` + `groupId`/`acceptGroups` for dragging items between
  multiple lists/grids (e.g. a kanban board).
* Callbacks: `onDragStart`, `onDragEnd`, `onReorder`, `onMove`, `onDrop`.
* Customizable drag preview (`dragPreviewBuilder`) and drop placeholder
  (`dragPlaceholderBuilder`), with sensible defaults.
* `isLoading`/`loadingBuilder` and empty-state/`emptyBuilder` support; an
  empty group remains a valid drop target.
* Builder-based (`ListView.builder`/`GridView.builder`), lazy for large
  datasets. No external dependencies.
