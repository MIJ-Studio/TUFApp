import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n.dart';
import '../../core/models/difficulty.dart';
import '../theme.dart';
import 'common.dart';
import 'motion.dart';

/// Difficulty range slider ported from the TUF website's DifficultySlider.
/// Two difficulty icon knobs pick a range on a track colored with the difficulty gradient.
///
/// - While dragging, the knob follows the pointer and [onChanged] fires once on release (so there is one search).
/// - When the value changes from outside (a reset, etc.), the knobs and range animate smoothly.
/// - Like a Material 3 slider, each knob takes keyboard focus: arrows move one step, Page Up/Down five,
///   Home/End to the ends, and [onChanged] fires once the keys settle.
class DifficultySlider extends StatefulWidget {
  const DifficultySlider({
    super.key,
    required this.difficulties,
    required this.lower,
    required this.upper,
    required this.onChanged,
  });

  final List<Difficulty> difficulties;
  final int lower;
  final int upper;
  final void Function(int lower, int upper) onChanged;

  @override
  State<DifficultySlider> createState() => _DifficultySliderState();
}

class _DifficultySliderState extends State<DifficultySlider> {
  static const side = 24.0;
  static const trackTop = 40.0;
  static const trackHeight = 12.0;
  static const _knobSize = 40.0;
  static const _labelWidth = 140.0;
  static const _height = 92.0;

  static const _moveDuration = Durations.medium1;
  static const _moveCurve = Motion.curve;

  late int _lower = _clamp(widget.lower);
  late int _upper = _clamp(widget.upper);

  /// 0: the grabbed knob is [_lower], 1: [_upper], null: not dragging
  int? _dragKnob;

  /// Keyboard focus for the lower (0) and upper (1) knob.
  late final _knobFocus = [FocusNode(debugLabel: 'lowest difficulty'), FocusNode(debugLabel: 'highest difficulty')];

  /// The knob showing a keyboard focus ring, if any.
  int? _focusedKnob;

  /// Reports keyboard moves once the keys settle, so holding an arrow doesn't search at every step.
  Timer? _keyCommit;
  static const _keyCommitDelay = Duration(milliseconds: 400);
  static const _pageStep = 5;

  static const _keys = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.pageDown): _StepIntent(-_pageStep),
    SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent(_pageStep),
    SingleActivator(LogicalKeyboardKey.home): _StepIntent.toStart,
    SingleActivator(LogicalKeyboardKey.end): _StepIntent.toEnd,
  };

  int get _maxIndex => max(0, widget.difficulties.length - 1);

  int _clamp(int index) => index.clamp(0, _maxIndex);

  @override
  void didUpdateWidget(DifficultySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragKnob == null && !(_keyCommit?.isActive ?? false)) {
      _lower = _clamp(widget.lower);
      _upper = _clamp(widget.upper);
    }
  }

  @override
  void dispose() {
    _keyCommit?.cancel();
    for (final node in _knobFocus) {
      node.dispose();
    }
    super.dispose();
  }

  /// Moves a knob by [delta] steps from the keyboard. The lower knob can't pass the upper one and vice versa.
  void _step(int knob, int delta) {
    setState(() {
      if (knob == 0) {
        _lower = (_lower + delta).clamp(0, _upper);
      } else {
        _upper = (_upper + delta).clamp(_lower, _maxIndex);
      }
    });
    _keyCommit?.cancel();
    _keyCommit = Timer(_keyCommitDelay, () {
      if (mounted && (_lower != widget.lower || _upper != widget.upper)) widget.onChanged(_lower, _upper);
    });
  }

  static double xAt(double index, int count, double width) {
    final usable = max(0.0, width - side * 2);
    return count <= 1 ? side : side + usable * index / (count - 1);
  }

  int _indexAt(double x, double width) {
    final count = widget.difficulties.length;
    if (count <= 1) return 0;
    final usable = max(1.0, width - side * 2);
    return (((x - side) / usable).clamp(0.0, 1.0) * (count - 1)).round();
  }

  void _onPointerDown(PointerDownEvent event, double width) {
    if (widget.difficulties.isEmpty) return;
    if (event.kind == PointerDeviceKind.mouse && (event.buttons & kPrimaryMouseButton) == 0) return;

    // Like the website, move the knob closer to the pressed position.
    final index = _indexAt(event.localPosition.dx, width);
    setState(() {
      _dragKnob = (_lower - index).abs() <= (_upper - index).abs() ? 0 : 1;
      _moveDragged(index);
    });
  }

  void _onPointerMove(PointerMoveEvent event, double width) {
    if (_dragKnob == null) return;
    final index = _indexAt(event.localPosition.dx, width);
    if ((_dragKnob == 0 ? _lower : _upper) != index) setState(() => _moveDragged(index));
  }

  void _moveDragged(int index) {
    if (_dragKnob == 0) {
      _lower = index;
    } else {
      _upper = index;
    }
  }

  /// On release, order the values and report them. Knobs may cross each other.
  void _commit() {
    if (_dragKnob == null) return;
    setState(() {
      _dragKnob = null;
      final low = min(_lower, _upper);
      final high = max(_lower, _upper);
      _lower = low;
      _upper = high;
    });
    if (_lower != widget.lower || _upper != widget.upper) widget.onChanged(_lower, _upper);
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.difficulties;
    if (list.isEmpty) return const SizedBox(height: _height);

    final colors = [for (final d in list) parseHexColor(d.color) ?? Colors.grey];
    final dragging = _dragKnob != null;
    final duration = dragging ? Duration.zero : _moveDuration;

    // Whether the dragged knob is currently the lower one (changes when knobs cross).
    final draggingLow = dragging && ((_dragKnob == 0) == (_lower <= _upper));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return MouseRegion(
          cursor: dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.click,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onPointerDown(e, width),
            onPointerMove: (e) => _onPointerMove(e, width),
            onPointerUp: (_) => _commit(),
            onPointerCancel: (_) => _commit(),
            child: SizedBox(
              width: width,
              height: _height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: min(_lower, _upper).toDouble()),
                duration: duration,
                curve: _moveCurve,
                builder: (context, low, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: max(_lower, _upper).toDouble()),
                  duration: duration,
                  curve: _moveCurve,
                  builder: (context, high, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrackPainter(colors: colors, low: low, high: high),
                        ),
                      ),
                      ..._knob(context, list, colors, low, width, knob: 0, active: draggingLow),
                      ..._knob(context, list, colors, high, width, knob: 1, active: dragging && !draggingLow),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _knob(
    BuildContext context,
    List<Difficulty> list,
    List<Color> colors,
    double position,
    double width, {
    required int knob,
    required bool active,
  }) {
    final index = position.round().clamp(0, list.length - 1);
    final difficulty = list[index];
    final color = colors[index];
    final x = xAt(position, list.length, width);

    // "GQ0 (G1~G4)" → "GQ0" on top, "(G1~G4)" below
    final words = difficulty.name.split(' ');
    final glow = _glowColor(difficulty, color);

    return [
      Positioned(
        left: x - _labelWidth / 2,
        top: trackTop + 30,
        width: _labelWidth,
        child: IgnorePointer(
          child: Text(
            words.length > 1 ? words.sublist(1).join(' ') : '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.2, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      Positioned(
        left: x - _knobSize / 2,
        top: trackTop + trackHeight / 2 - _knobSize / 2,
        child: Semantics(
          slider: true,
          label: knob == 0 ? l10n.lowestDifficulty : l10n.highestDifficulty,
          value: difficulty.name,
          increasedValue: list[min(index + 1, list.length - 1)].name,
          decreasedValue: list[max(index - 1, 0)].name,
          onIncrease: () => _step(knob, 1),
          onDecrease: () => _step(knob, -1),
          child: FocusableActionDetector(
            focusNode: _knobFocus[knob],
            shortcuts: _keys,
            actions: {_StepIntent: CallbackAction<_StepIntent>(onInvoke: (intent) => _step(knob, intent.delta))},
            onShowFocusHighlight: (focused) => setState(() {
              if (focused) {
                _focusedKnob = knob;
              } else if (_focusedKnob == knob) {
                _focusedKnob = null;
              }
            }),
            // The whole slider handles the pointer; the knob only takes keyboard focus.
            child: IgnorePointer(
              child: AnimatedScale(
                scale: active ? 1.15 : 1,
                duration: Durations.short3,
                curve: Motion.standard,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: active ? 10 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: NetworkIcon(difficulty.icon, size: _knobSize),
                    ),
                    // Material 3 focus indicator: 3 dp ring, 2 dp outside the knob.
                    Positioned(
                      left: -5,
                      top: -5,
                      right: -5,
                      bottom: -5,
                      child: AnimatedOpacity(
                        opacity: _focusedKnob == knob ? 1 : 0,
                        duration: Motion.fast,
                        curve: Motion.standard,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: x - _labelWidth / 2,
        top: 0,
        width: _labelWidth,
        child: IgnorePointer(
          child: AnimatedDefaultTextStyle(
            duration: Durations.short3,
            style: TextStyle(
              fontSize: 17.6,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 2),
                const Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                Shadow(color: glow, blurRadius: 12),
                Shadow(color: glow, blurRadius: 12),
              ],
            ),
            child: Text(words.first, textAlign: TextAlign.center),
          ),
        ),
      ),
    ];
  }

  /// Like the website, U14 and above and Q difficulties glow white.
  static Color _glowColor(Difficulty difficulty, Color color) {
    final name = difficulty.name;
    if (name.startsWith('U')) {
      final number = int.tryParse(name.substring(1));
      if (number != null && number > 13) return Colors.white;
    }
    if (name.startsWith('Q')) return Colors.white;
    return color;
  }
}

/// Draws the whole track dimmed and the selected range vivid with a soft glow.
/// [low]/[high] can be fractional during animations.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({required this.colors, required this.low, required this.high});

  final List<Color> colors;
  final double low;
  final double high;

  @override
  void paint(Canvas canvas, Size size) {
    final count = colors.length;
    if (count < 2) return;

    const side = _DifficultySliderState.side;
    const top = _DifficultySliderState.trackTop;
    const height = _DifficultySliderState.trackHeight;
    final usable = max(0.0, size.width - side * 2);

    final trackRect = Rect.fromLTWH(side, top, usable, height);
    canvas.saveLayer(trackRect.inflate(2), Paint()..color = Colors.white.withValues(alpha: 0.28));
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(6)),
      Paint()..shader = LinearGradient(colors: colors).createShader(trackRect),
    );
    canvas.restore();

    final left = _DifficultySliderState.xAt(low, count, size.width);
    final right = _DifficultySliderState.xAt(high, count, size.width);
    if (right - left < 1) return;

    final rangeRect = Rect.fromLTRB(left, top - 4, right, top + height + 4);
    final range = RRect.fromRectAndRadius(rangeRect, const Radius.circular(12));
    canvas.drawRRect(
      range,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(range, Paint()..shader = _rangeGradient().createShader(rangeRect));
  }

  /// Builds the gradient from the difficulty colors in range, positioned correctly even with fractional ends.
  LinearGradient _rangeGradient() {
    final first = low.floor();
    final last = min(colors.length - 1, high.ceil());
    final span = high - low;

    final stops = <double>[];
    final rangeColors = <Color>[];
    for (var i = first; i <= last; i++) {
      stops.add(((i - low) / span).clamp(0.0, 1.0));
      rangeColors.add(colors[i]);
    }
    if (rangeColors.length < 2) return LinearGradient(colors: [rangeColors.first, rangeColors.first]);
    return LinearGradient(colors: rangeColors, stops: stops);
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) =>
      oldDelegate.low != low || oldDelegate.high != high || !listEquals(oldDelegate.colors, colors);
}

/// Moves a slider knob from the keyboard by [delta] steps (clamped to the ends).
class _StepIntent extends Intent {
  const _StepIntent(this.delta);

  final int delta;

  static const toStart = _StepIntent(-1 << 20);
  static const toEnd = _StepIntent(1 << 20);
}
