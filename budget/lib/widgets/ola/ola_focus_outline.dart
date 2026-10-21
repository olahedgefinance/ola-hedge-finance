import 'package:budget/brand/ola_theme.dart';
import 'package:flutter/material.dart';

/// Observes the existing control's focus without adding a traversal stop.
/// A surface-coloured separator keeps the focus colour distinct from accent fills.
class OlaFocusOutline extends StatefulWidget {
  const OlaFocusOutline({super.key, required this.child, required this.radius});
  final Widget child;
  final BorderRadius radius;
  @override
  State<OlaFocusOutline> createState() => _OlaFocusOutlineState();
}

class _OlaFocusOutlineState extends State<OlaFocusOutline> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = theme.extension<OlaSemanticColors>() ??
        OlaSemanticColors.forBrightness(theme.brightness);
    return Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => focused = value),
        child: CustomPaint(
            foregroundPainter: focused
                ? _FocusPainter(widget.radius, roles.focusVisible,
                    theme.colorScheme.surface)
                : null,
            child: widget.child));
  }
}

class _FocusPainter extends CustomPainter {
  const _FocusPainter(this.radius, this.color, this.separator);
  final BorderRadius radius;
  final Color color, separator;
  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size).deflate(3);
    canvas.drawRRect(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = separator);
    canvas.drawRRect(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(_FocusPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      color != oldDelegate.color ||
      separator != oldDelegate.separator;
}
