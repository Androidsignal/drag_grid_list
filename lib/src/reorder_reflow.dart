import 'package:flutter/widgets.dart';

/// Wraps [child] and smoothly slides it from its last on-screen position
/// to wherever it lands next, instead of snapping.
///
/// Must be constructed with a [key] that's stable per logical item (e.g. a
/// [GlobalKey] cached by the item's id, not its list index). That's what
/// lets Flutter *move* this widget's [Element] — and therefore its
/// [State], including the position it remembers — when the item's slot in
/// the list changes, rather than tearing it down and building a fresh one.
///
/// Used internally by `DragGridList` to reflow items after a reorder.
class ReorderReflow extends StatefulWidget {
  /// Creates a reflow wrapper. [key] should be a per-item-identity
  /// [GlobalKey], not a positional one.
  const ReorderReflow({
    required Key key,
    required this.duration,
    this.curve = Curves.easeOutCubic,
    required this.child,
  }) : super(key: key);

  /// How long the slide-into-place animation takes.
  final Duration duration;

  /// Easing applied to the slide.
  final Curve curve;

  /// The item's normal visual.
  final Widget child;

  @override
  State<ReorderReflow> createState() => _ReorderReflowState();
}

class _ReorderReflowState extends State<ReorderReflow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Animation<Offset> _offset = const AlwaysStoppedAnimation<Offset>(
    Offset.zero,
  );
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordPosition());
  }

  @override
  void didUpdateWidget(covariant ReorderReflow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _reflow());
  }

  Offset? _currentGlobalPosition() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero);
  }

  void _recordPosition() {
    if (!mounted) return;
    _lastPosition = _currentGlobalPosition();
  }

  void _reflow() {
    if (!mounted) return;
    final newPosition = _currentGlobalPosition();
    final oldPosition = _lastPosition;
    _lastPosition = newPosition;
    if (oldPosition == null ||
        newPosition == null ||
        oldPosition == newPosition) {
      return;
    }

    final delta = oldPosition - newPosition;
    setState(() {
      _offset = Tween<Offset>(begin: delta, end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
    });
    _controller
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: _offset.value, child: child),
      child: widget.child,
    );
  }
}
