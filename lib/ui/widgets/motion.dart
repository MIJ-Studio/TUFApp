import 'dart:async';

import 'package:flutter/material.dart';

/// Animation durations and easing shared across the app, from the Material 3 motion tokens
/// (Flutter's [Durations] and [Easing]).
abstract final class Motion {
  static const fast = Durations.short3; // 150 ms
  static const medium = Durations.medium1; // 250 ms
  static const slow = Durations.medium3; // 350 ms

  /// Something on screen moves or changes size, starting and ending on screen (M3 "emphasized").
  static const curve = Curves.easeInOutCubicEmphasized;

  /// Something appears or grows into view (M3 "emphasized decelerate").
  static const enter = Easing.emphasizedDecelerate;

  /// Something leaves or shrinks out of view (M3 "emphasized accelerate").
  static const exit = Easing.emphasizedAccelerate;

  /// [exit] for animations that run backwards (a reversing controller, AnimatedSwitcher's outgoing child).
  static const exitReversed = FlippedCurve(exit);

  /// Small utility changes such as colors, opacity and state layers (M3 "standard").
  static const standard = Easing.standard;
}

/// Cross-fades when the content changes. The child needs a different key or widget type to switch.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = Motion.medium,
    this.scale = false,
  });

  final Widget child;
  final Alignment alignment;
  final Duration duration;

  /// Scales up slightly while appearing (button state changes, etc.).
  final bool scale;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    switchInCurve: Motion.enter,
    switchOutCurve: Motion.exitReversed,
    layoutBuilder: (current, previous) => Stack(alignment: alignment, children: [...previous, ?current]),
    transitionBuilder: (child, animation) {
      final faded = FadeTransition(opacity: animation, child: child);
      return scale ? ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(animation), child: faded) : faded;
    },
    child: child,
  );
}

/// Expands from the top or collapses with [visible]. Fully collapsed, the child isn't built.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.visible, required this.child, this.duration = Motion.slow});

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  )..addStatusListener((_) => setState(() {}));

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
    reverseCurve: Motion.exitReversed,
  );

  @override
  void didUpdateWidget(Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed && !widget.visible) return const SizedBox(width: double.infinity);
    // Clip only while animating; once expanded, glows and labels may extend outside.
    // (The widget structure must stay the same so the child's state isn't recreated when the animation ends.)
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => ClipRect(
        clipBehavior: _controller.isAnimating ? Clip.hardEdge : Clip.none,
        child: Align(alignment: Alignment.topCenter, heightFactor: _curved.value, child: child),
      ),
      child: FadeTransition(opacity: _curved, child: widget.child),
    );
  }
}

/// Slides up slightly and fades in when first built. Shown immediately if [animate] is false.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.animate = true, this.delay = Duration.zero});

  final Widget child;
  final bool animate;
  final Duration delay;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  /// Created only if [Appear.animate] was true when first built; not created when shown without animation
  /// (cheaper during fast scrolling).
  ///
  /// Disposal is decided by this value. The widget's animate can change later (true at first, false on the next build),
  /// so deciding by it would leak a running animation.
  AnimationController? _controller;
  Animation<double>? _curved;
  Animation<Offset>? _offset;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;

    final controller = _controller = AnimationController(vsync: this, duration: Motion.slow);
    final curved = _curved = CurvedAnimation(parent: controller, curve: Motion.enter);
    _offset = Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved);
    if (widget.delay == Duration.zero) {
      controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = _curved;
    final offset = _offset;
    if (curved == null || offset == null) return widget.child;
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}

/// Material 3 filled card (medium corner shape).
///
/// With [onTap] it is interactive like a Material 3 card: a state layer shows hover (8%), focus and press (10%),
/// keyboard focus draws a focus ring, and Enter or Space open it like a click.
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.background,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Makes the card tappable (opening a folder, etc.).
  final VoidCallback? onTap;

  /// Background behind the card (video thumbnail, etc.), clipped to the card shape.
  final Widget Function(BuildContext context, bool hovered)? background;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  static const _radius = 12.0;

  /// Material 3 focus indicator: 3 dp thick, 2 dp outside the card.
  static const _focusWidth = 3.0;
  static const _focusGap = 2.0;

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  /// Opacity of the state layer, from the Material 3 interaction state tokens.
  double get _stateOpacity {
    if (!_interactive) return 0;
    if (_pressed || _focused) return 0.10;
    if (_hovered) return 0.08;
    return 0;
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  void didUpdateWidget(HoverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _pressed = _focused = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(_radius)),
      child: Stack(
        children: [
          if (widget.background case final background?) Positioned.fill(child: background(context, _hovered)),
          // The state layer sits over the container (and its background image) but under the content.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.standard,
                color: colors.onSurface.withValues(alpha: _stateOpacity),
              ),
            ),
          ),
          AnimatedPadding(
            duration: Motion.medium,
            curve: Motion.curve,
            padding: widget.padding,
            child: AnimatedSize(
              duration: Motion.medium,
              curve: Motion.curve,
              alignment: Alignment.topCenter,
              child: widget.child,
            ),
          ),
        ],
      ),
    );

    // Hover is tracked even when the card isn't interactive, because the background reacts to it.
    return MouseRegion(
      cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        enabled: _interactive,
        // Only keyboard focus is highlighted, not focus that follows a click.
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        // Space sends ActivateIntent and Enter sends ButtonActivateIntent.
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
        },
        child: Semantics(
          button: _interactive,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: _interactive ? (_) => _setPressed(true) : null,
            onTapUp: _interactive ? (_) => _setPressed(false) : null,
            onTapCancel: _interactive ? () => _setPressed(false) : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                card,
                Positioned.fill(
                  left: -(_focusGap + _focusWidth),
                  top: -(_focusGap + _focusWidth),
                  right: -(_focusGap + _focusWidth),
                  bottom: -(_focusGap + _focusWidth),
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _focused ? 1 : 0,
                      duration: Motion.fast,
                      curve: Motion.standard,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_radius + _focusGap + _focusWidth),
                          border: Border.all(color: colors.secondary, width: _focusWidth),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
