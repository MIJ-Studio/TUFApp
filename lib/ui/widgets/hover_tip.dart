import 'dart:async';

import 'package:flutter/material.dart';

/// Lightweight tooltip for list cards that contain dozens of them.
///
/// The built-in [Tooltip] inspects every pointer event on screen (mouse moves, wheel) in each tooltip
/// and creates animation controllers then. With 10+ per card, one wheel tick wakes hundreds of them,
/// and fast scrolling even throws errors.
/// This widget only works while the mouse is actually over it and shows one tip at a time.
class HoverTip extends StatefulWidget {
  const HoverTip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  /// How long the mouse must rest before the tip shows.
  static const delay = Duration(milliseconds: 500);

  @override
  State<HoverTip> createState() => _HoverTipState();
}

class _HoverTipState extends State<HoverTip> {
  /// The tip currently shown; showing a new one closes it.
  static _HoverTipState? _shown;

  Timer? _timer;
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    // Moving between tips while one is open shows the next one immediately.
    _timer = Timer(_shown != null ? Duration.zero : HoverTip.delay, _show);
  }

  void _show() {
    if (!mounted || widget.message.isEmpty) return;
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (box is! RenderBox || !box.attached || overlay == null) return;

    _shown?._hide();
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final target = box.localToGlobal(box.size.center(Offset.zero), ancestor: overlayBox);
    final verticalOffset = box.size.height / 2 + 6;

    _entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TipLayout(target: target, verticalOffset: verticalOffset),
          child: _TipBubble(message: widget.message),
        ),
      ),
    );
    overlay.insert(_entry!);
    _shown = this;
  }

  void _hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    if (identical(_shown, this)) _shown = null;
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _schedule(),
    onExit: (_) => _hide(),
    child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
  );
}

class _TipLayout extends SingleChildLayoutDelegate {
  const _TipLayout({required this.target, required this.verticalOffset});

  final Offset target;
  final double verticalOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => positionDependentBox(
    size: size,
    childSize: childSize,
    target: target,
    verticalOffset: verticalOffset,
    preferBelow: true,
    margin: 8,
  );

  @override
  bool shouldRelayout(_TipLayout oldDelegate) =>
      target != oldDelegate.target || verticalOffset != oldDelegate.verticalOffset;
}

/// Bubble shaped like the built-in tooltip, with a short fade-in.
class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooltipTheme = TooltipTheme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Durations.short3,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            tooltipTheme.decoration ??
            BoxDecoration(color: Colors.grey[700]!.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(4)),
        child: Text(message, style: tooltipTheme.textStyle ?? theme.textTheme.bodySmall?.copyWith(color: Colors.white)),
      ),
    );
  }
}
