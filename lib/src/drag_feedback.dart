import 'package:flutter/material.dart';

/// Default drag preview: an elevated, slightly scaled copy of the item.
///
/// Fed to `Draggable.feedback` when the consumer doesn't supply a
/// `dragPreviewBuilder`.
class DefaultDragPreview extends StatelessWidget {
  /// Creates the default drag preview.
  const DefaultDragPreview({
    super.key,
    required this.child,
    this.width,
    this.height,
  });

  /// The item's normal (non-dragging) visual.
  final Widget child;

  /// Locks the preview to the source slot's width, if known.
  final double? width;

  /// Locks the preview to the source slot's height, if known.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.03,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: SizedBox(
          width: width,
          height: height,
          child: Opacity(opacity: 0.92, child: child),
        ),
      ),
    );
  }
}

/// Default placeholder left behind in the source slot while an item drags:
/// a dashed, dimmed box the same size as the item. Avoids layout jump.
class DefaultDragPlaceholder extends StatelessWidget {
  /// Creates the default drag placeholder.
  const DefaultDragPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  /// Placeholder width, matching the source slot.
  final double? width;

  /// Placeholder height, matching the source slot.
  final double? height;

  /// Corner radius of the placeholder box.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color, borderRadius: borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  static const double _dashWidth = 6;
  static const double _dashGap = 4;
  static const double _strokeWidth = 1.5;

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}

/// Visual reject cue shown on a [DragTarget] that doesn't accept the
/// hovering item's group: a red-tinted outline flash.
class DragRejectOverlay extends StatelessWidget {
  /// Creates the reject overlay.
  const DragRejectOverlay({super.key, this.borderRadius = 8});

  /// Corner radius matching the underlying content.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
