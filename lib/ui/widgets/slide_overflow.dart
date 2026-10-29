import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'motion.dart';

/// Softly fades out the overflowing end, **horizontally only**, when content is wider than its box.
/// The child is laid out without a width limit, so it can hold widgets that break when squeezed, like a Row.
///
/// Paints shifted left by [offset] (used by the sliding animation).
/// Content that fits is painted directly without a layer.
class FadeEdges extends SingleChildRenderObjectWidget {
  const FadeEdges({super.key, required Widget super.child, this.offset = 0, this.fadeWidth = 16});

  final double offset;
  final double fadeWidth;

  @override
  RenderFadeEdges createRenderObject(BuildContext context) => RenderFadeEdges(offset: offset, fadeWidth: fadeWidth);

  @override
  void updateRenderObject(BuildContext context, RenderFadeEdges renderObject) {
    renderObject
      ..offset = offset
      ..fadeWidth = fadeWidth;
  }
}

class RenderFadeEdges extends RenderProxyBox {
  RenderFadeEdges({required double offset, required double fadeWidth})
    // ignore: prefer_initializing_formals
    : _offset = offset,
      // ignore: prefer_initializing_formals
      _fadeWidth = fadeWidth;

  double _offset;
  double _fadeWidth;

  /// How far the content is currently shifted left.
  double get offset => _offset;

  set offset(double value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  set fadeWidth(double value) {
    if (_fadeWidth == value) return;
    _fadeWidth = value;
    markNeedsPaint();
  }

  /// How much wider the content is than the box; 0 if it fits.
  double get overflow {
    final child = this.child;
    if (child == null || !hasSize) return 0;
    return (child.size.width - size.width).clamp(0.0, double.infinity);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    final wasOverflowing = hasSize && overflow > 0;
    // No width limit (an overflowing Row won't throw); height as given by the parent.
    child.layout(
      BoxConstraints(minHeight: constraints.minHeight, maxHeight: constraints.maxHeight),
      parentUsesSize: true,
    );
    size = constraints.constrain(child.size);
    // Whether a mask layer is needed changes when overflow starts or stops.
    if (wasOverflowing != overflow > 0) markNeedsCompositingBitsUpdate();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(-_offset, 0),
      position: position,
      hitTest: (result, transformed) => child.hitTest(result, position: transformed),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final childOffset = offset + Offset(-_offset, 0);
    // Content that fits needs no layer or clip (important, since lists hold hundreds of these).
    if (overflow <= 0 && _offset <= 0) {
      context.paintChild(child, childOffset);
      return;
    }

    final fadeStart = _offset > 0.5;
    final fadeEnd = _offset < overflow - 0.5;
    if (!fadeStart && !fadeEnd) {
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, (context, offset) {
        context.paintChild(child, childOffset);
      });
      return;
    }

    // The edge is faded the same way ShaderMask does it (a mask layer).
    // Opening and closing layers directly on the canvas breaks when the
    // content needs its own layers (icons fading in, etc.),
    // because the canvas changes in between. A mask layer wraps such content too.
    //
    // At fractional offsets, edge pixels only half overlap the box and layer bounds round to whole pixels.
    // Fading exactly at the box size leaves a stray column, so the clip is
    // slightly wider than the box and the fade wider still.
    // The gradient clamps its end colors, so the area widened past the box is faded out completely.
    const clipOut = 2.0;
    const maskOut = 6.0;
    final fade = (_fadeWidth / size.width).clamp(0.0, 0.5);
    final mask = Rect.fromLTRB(
      offset.dx - maskOut,
      offset.dy - maskOut,
      offset.dx + size.width + maskOut,
      offset.dy + size.height + maskOut,
    );

    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTRB(-clipOut, 0, size.width + clipOut, size.height),
      oldLayer: _clipLayer.layer,
      (context, offset) {
        final layer = _maskLayer.layer ??= ShaderMaskLayer();
        layer
          ..maskRect = mask
          ..blendMode = BlendMode.dstIn
          // Shader coordinates are relative to the top left of the mask rect.
          ..shader = ui.Gradient.linear(
            Offset(maskOut, maskOut + size.height / 2),
            Offset(maskOut + size.width, maskOut + size.height / 2),
            const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            [0, fadeStart ? fade : 0, fadeEnd ? 1 - fade : 1, 1],
          );
        context.pushLayer(layer, (context, _) => context.paintChild(child, childOffset), Offset.zero);
      },
    );
  }

  final _maskLayer = LayerHandle<ShaderMaskLayer>();
  final _clipLayer = LayerHandle<ClipRectLayer>();

  /// Overflowing content uses a mask layer, so compositing is needed.
  @override
  bool get alwaysNeedsCompositing => child != null && (overflow > 0 || _offset > 0);

  @override
  void dispose() {
    _maskLayer.layer = null;
    _clipLayer.layer = null;
    super.dispose();
  }
}

/// When content is wider than its box, hovering scrolls it to the end
/// and holds it there; leaving returns it to the start.
/// Otherwise it stays still with the overflowing end faded.
class SlideOverflow extends StatefulWidget {
  const SlideOverflow({super.key, required this.child});

  final Widget child;

  @override
  State<SlideOverflow> createState() => _SlideOverflowState();
}

class _SlideOverflowState extends State<SlideOverflow> with SingleTickerProviderStateMixin {
  /// Scroll speed (pixels per second).
  static const _speedPerSecond = 60.0;

  /// Returning is fast.
  static const _returnDuration = Durations.medium2;

  late final AnimationController _controller = AnimationController(vsync: this);
  final _key = GlobalKey();
  bool _hovered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _overflow {
    final render = _key.currentContext?.findRenderObject();
    return render is RenderFadeEdges ? render.overflow : 0.0;
  }

  /// Layout is already done when the mouse enters, so start immediately.
  /// (Waiting for the next frame would never start if nothing else schedules a frame.)
  void _onEnter() {
    _hovered = true;
    final distance = _overflow;
    if (distance <= 1) return;

    final remaining = distance * (1 - _controller.value);
    final ms = (remaining / _speedPerSecond * 1000).round().clamp(300, 8000);
    _controller.animateTo(
      1,
      duration: Duration(milliseconds: ms),
      curve: Motion.standard,
    );
  }

  void _onExit() {
    if (!_hovered) return;
    _hovered = false;
    if (_controller.value == 0 && !_controller.isAnimating) return;
    _controller.animateTo(0, duration: _returnDuration, curve: Motion.standard);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _onEnter(),
    onExit: (_) => _onExit(),
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FadeEdges(key: _key, offset: _overflow * _controller.value, child: child!),
      child: widget.child,
    ),
  );
}

/// Single-line text for sliding, with wrapping and ellipsis off.
/// Fading the end is left to [FadeEdges], horizontally only.
Text slidingText(String text, {TextStyle? style}) =>
    Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.clip, style: style);
