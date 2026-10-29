import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/profile_stats.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Chart colors, taken from the app theme.
class _ChartColors {
  _ChartColors(ThemeData theme)
    : axis = theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
      grid = theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      line = theme.colorScheme.primary,
      hover = theme.colorScheme.onSurface.withValues(alpha: 0.06),
      surface = theme.colorScheme.surfaceContainerLow;

  final TextStyle axis;
  final Color grid;
  final Color line;
  final Color hover;
  final Color surface;
}

/// Small tooltip box over a chart (same background as other floating boxes in the app).
BoxDecoration _tooltipBox(ThemeData theme) => BoxDecoration(
  color: theme.colorScheme.surfaceContainerHigh,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: theme.colorScheme.outlineVariant),
  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4))],
);

/// Picks a tick step of 1, 2 or 5 × 10ⁿ.
double _niceStep(double range, int count) {
  if (range <= 0) return 1;
  final rough = range / count;
  final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
  final normalized = rough / magnitude;
  final step = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return max(1, step * magnitude);
}

Color _hex(String? value, Color fallback) {
  final hex = value?.replaceFirst('#', '');
  if (hex == null || (hex.length != 6 && hex.length != 8)) return fallback;
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

// ───────────────────────── Difficulty chart ─────────────────────────

/// Bar chart per difficulty, colored by difficulty. Hovering shows the icon and count.
class DifficultyBarChart extends StatefulWidget {
  const DifficultyBarChart({super.key, required this.bars, required this.levels});

  final List<DifficultyBar> bars;

  /// Whether bars count levels (otherwise clears).
  final bool levels;

  static const height = 300.0;

  @override
  State<DifficultyBarChart> createState() => _DifficultyBarChartState();
}

class _DifficultyBarChartState extends State<DifficultyBarChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    final colors = _ChartColors(Theme.of(context));
    return SizedBox(
      height: DifficultyBarChart.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _BarLayout(bars, constraints.biggest);
          final hover = _hover;
          return MouseRegion(
            onHover: (event) => setState(() => _hover = layout.indexAt(event.localPosition)),
            onExit: (_) => setState(() => _hover = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    // Bars grow when first shown and when values change (like the website's recharts).
                    key: ValueKey(Object.hashAll(bars.map((bar) => bar.count))),
                    tween: Tween(begin: 0, end: 1),
                    duration: Durations.extralong1,
                    curve: Motion.enter,
                    builder: (context, progress, _) => CustomPaint(
                      painter: _BarPainter(layout: layout, hover: hover, progress: progress, colors: colors),
                    ),
                  ),
                ),
                if (hover != null) _tooltip(layout, hover),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tooltip(_BarLayout layout, int index) {
    final theme = Theme.of(context);
    final bar = layout.bars[index];
    final rect = layout.barRect(index, 1);
    final color = _hex(bar.difficulty.color, const Color(0xFFFF2AD1));
    const width = 190.0;
    final left = (rect.center.dx + 12).clamp(0.0, layout.size.width - width);
    return Positioned(
      left: rect.center.dx + 12 + width > layout.size.width ? rect.center.dx - width - 12 : left,
      top: max(0, rect.top - 60),
      child: IgnorePointer(
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: _tooltipBox(theme),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NetworkIcon(bar.difficulty.icon, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    bar.difficulty.name,
                    style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: Text(
                  widget.levels ? l10n.levelCount(bar.count) : l10n.clearCount(bar.count),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar chart geometry, shared by painting and hit testing.
class _BarLayout {
  _BarLayout(this.bars, this.size) {
    final top = bars.fold(0, (value, bar) => max(value, bar.count));
    step = _niceStep(max(top, 1).toDouble(), 4);
    yMax = max(step, (top / step).ceil() * step);
    plot = Rect.fromLTRB(45, 20, size.width - 30, size.height - 30);
  }

  final List<DifficultyBar> bars;
  final Size size;
  late final double step;
  late final double yMax;
  late final Rect plot;

  double get slot => bars.isEmpty ? 0 : plot.width / bars.length;

  Rect barRect(int index, double progress) {
    final height = plot.height * bars[index].count / yMax * progress;
    final left = plot.left + slot * index;
    // Overlap by half a pixel so no gaps show between bars (the website's barCategoryGap -0.5).
    return Rect.fromLTRB(left - 0.25, plot.bottom - height, left + slot + 0.25, plot.bottom);
  }

  int? indexAt(Offset position) {
    if (!plot.inflate(4).contains(position) || bars.isEmpty) return null;
    return ((position.dx - plot.left) / slot).floor().clamp(0, bars.length - 1);
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.layout, required this.hover, required this.progress, required this.colors});

  final _BarLayout layout;
  final int? hover;
  final double progress;
  final _ChartColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = layout.plot;
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;

    // Horizontal grid (dashed) and left labels.
    for (var value = 0.0; value <= layout.yMax + 0.01; value += layout.step) {
      final y = plot.bottom - plot.height * value / layout.yMax;
      for (var x = plot.left; x < plot.right; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(min(x + 3, plot.right), y), grid);
      }
      _text(canvas, value.round().toString(), Offset(plot.left - 8, y), alignRight: true);
    }

    if (hover case final index?) {
      final slot = layout.slot;
      canvas.drawRect(
        Rect.fromLTWH(plot.left + slot * index, plot.top, slot, plot.height),
        Paint()..color = colors.hover,
      );
    }

    for (var i = 0; i < layout.bars.length; i++) {
      final bar = layout.bars[i];
      if (bar.count <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          layout.barRect(i, progress),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = _hex(bar.difficulty.color, const Color(0xFFFF2AD1)),
      );
    }

    // Bottom axis: line and names (every other one).
    canvas.drawLine(Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), Paint()..color = colors.grid);
    for (var i = 0; i < layout.bars.length; i += 2) {
      _text(canvas, layout.bars[i].label, Offset(plot.left + layout.slot * (i + 0.5), plot.bottom + 6), center: true);
    }
  }

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = false, bool center = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: colors.axis),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? at.dx - painter.width
        : center
        ? at.dx - painter.width / 2
        : at.dx;
    final dy = alignRight ? at.dy - painter.height / 2 : at.dy;
    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.hover != hover ||
      oldDelegate.progress != progress ||
      oldDelegate.layout.bars != layout.bars ||
      oldDelegate.layout.size != layout.size;
}

// ───────────────────────── Rank history ─────────────────────────

/// Rank history line chart. The vertical axis is flipped so rank 1 is at the top.
class RankHistoryChart extends StatefulWidget {
  const RankHistoryChart({super.key, required this.points});

  /// Dates and ranks. The line breaks on days without a rank.
  final List<({DateTime date, int? rank})> points;

  static const height = 320.0;

  @override
  State<RankHistoryChart> createState() => _RankHistoryChartState();
}

class _RankHistoryChartState extends State<RankHistoryChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: RankHistoryChart.height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final colors = _ChartColors(Theme.of(context));
        final layout = _LineLayout(widget.points, constraints.biggest);
        final hover = _hover;
        return MouseRegion(
          onHover: (event) => setState(() => _hover = layout.indexAt(event.localPosition)),
          onExit: (_) => setState(() => _hover = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(Object.hashAll(widget.points.map((point) => point.rank))),
                  tween: Tween(begin: 0, end: 1),
                  duration: Durations.extralong3,
                  curve: Motion.enter,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _LinePainter(layout: layout, hover: hover, progress: progress, colors: colors),
                  ),
                ),
              ),
              if (hover != null && widget.points[hover].rank != null) _tooltip(layout, hover),
            ],
          ),
        );
      },
    ),
  );

  Widget _tooltip(_LineLayout layout, int index) {
    final theme = Theme.of(context);
    final point = widget.points[index];
    final at = layout.pointAt(index)!;
    final today = DateTime.now().toUtc();
    final days = DateTime.utc(today.year, today.month, today.day).difference(point.date).inDays;
    final when = days <= 0
        ? l10n.today
        : days == 1
        ? l10n.oneDayAgo
        : l10n.daysAgo(days);
    const width = 120.0;
    return Positioned(
      left: at.dx + 14 + width > layout.size.width ? at.dx - width - 14 : at.dx + 14,
      top: (at.dy - 28).clamp(0, layout.size.height - 60),
      child: IgnorePointer(
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: _tooltipBox(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(when, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                '#${formatNumber(point.rank ?? 0)}',
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineLayout {
  _LineLayout(this.points, this.size) {
    final ranks = [for (final point in points) ?point.rank];
    if (ranks.isEmpty) {
      low = 1;
      high = 11;
    } else {
      final best = ranks.reduce(min);
      final worst = ranks.reduce(max);
      low = best < 1 ? best - 5 : max(1, best - 5);
      high = max(worst + 5, low + 5);
    }
    plot = Rect.fromLTRB(44, 8, size.width - 12, size.height - 26);
  }

  final List<({DateTime date, int? rank})> points;
  final Size size;
  late final int low;
  late final int high;
  late final Rect plot;

  double xOf(int index) => points.length < 2 ? plot.center.dx : plot.left + plot.width * index / (points.length - 1);
  double yOf(num rank) => plot.top + plot.height * (rank - low) / max(1, high - low);

  Offset? pointAt(int index) {
    final rank = points[index].rank;
    return rank == null ? null : Offset(xOf(index), yOf(rank));
  }

  int? indexAt(Offset position) {
    if (points.isEmpty || !plot.inflate(6).contains(position)) return null;
    if (points.length == 1) return 0;
    return ((position.dx - plot.left) / plot.width * (points.length - 1)).round().clamp(0, points.length - 1);
  }

  /// Vertical ticks: five or six, including both ends.
  List<int> get ticks {
    final step = _niceStep((high - low).toDouble(), 5).round();
    final start = (low / step).ceil() * step;
    return {low, for (var value = start; value <= high; value += step) value, high}.toList()..sort();
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.layout, required this.hover, required this.progress, required this.colors});

  final _LineLayout layout;
  final int? hover;
  final double progress;
  final _ChartColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = layout.plot;
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    final label = colors.axis;

    for (final tick in layout.ticks) {
      final y = layout.yOf(tick);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, '$tick', Offset(plot.left - 6, y), label, alignRight: true);
    }
    _text(canvas, l10n.rank, Offset(8, plot.center.dy), label, rotate: true);
    canvas.drawLine(Offset(plot.left, plot.top), Offset(plot.left, plot.bottom), grid);
    canvas.drawLine(Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), grid);

    // Bottom axis dates, only as many as fit without overlapping.
    final points = layout.points;
    if (points.isNotEmpty) {
      final count = max(1, (plot.width / 70).floor());
      final stride = max(1, (points.length / count).ceil());
      // Year and month beyond a year, otherwise month and day.
      final long = points.last.date.difference(points.first.date).inDays > 366;
      for (var i = 0; i < points.length; i += stride) {
        final date = points[i].date;
        final text = long ? formatShortMonth(date) : formatMonthDay(date);
        _text(canvas, text, Offset(layout.xOf(i), plot.bottom + 6), label, center: true);
      }
    }

    // Line: gaps are not bridged. It draws in from the left when first shown.
    final line = Paint()
      ..color = colors.line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final visible = (points.length * progress).ceil();
    Path? path;
    Offset? previous;
    for (var i = 0; i < visible; i++) {
      final point = layout.pointAt(i);
      if (point == null) {
        if (path != null) canvas.drawPath(path, line);
        path = null;
        previous = null;
        continue;
      }
      if (path == null || previous == null) {
        path = Path()..moveTo(point.dx, point.dy);
      } else {
        // Curve through the midpoint instead of stepping (recharts' bump).
        final middle = (previous.dx + point.dx) / 2;
        path.cubicTo(middle, previous.dy, middle, point.dy, point.dx, point.dy);
      }
      previous = point;
    }
    if (path != null) canvas.drawPath(path, line);

    if (hover case final index? when index < visible) {
      if (layout.pointAt(index) case final point?) {
        canvas.drawLine(Offset(point.dx, plot.top), Offset(point.dx, plot.bottom), Paint()..color = colors.grid);
        canvas.drawCircle(point, 6, Paint()..color = colors.surface);
        canvas.drawCircle(point, 4.5, Paint()..color = colors.line);
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    bool alignRight = false,
    bool center = false,
    bool rotate = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    if (rotate) {
      canvas.save();
      canvas.translate(at.dx + painter.height / 2, at.dy + painter.width / 2);
      canvas.rotate(-pi / 2);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      final dx = alignRight
          ? at.dx - painter.width
          : center
          ? at.dx - painter.width / 2
          : at.dx;
      painter.paint(canvas, Offset(dx, alignRight ? at.dy - painter.height / 2 : at.dy));
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.hover != hover ||
      oldDelegate.progress != progress ||
      oldDelegate.layout.points != layout.points ||
      oldDelegate.layout.size != layout.size;
}
