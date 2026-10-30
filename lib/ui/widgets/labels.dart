import 'package:flutter/material.dart';

import 'hover_tip.dart';

// The app's small labels, so the same kind of information looks the same everywhere:
//
// - InfoChip: a small fact next to other content: a category or status (WF, key count, game version,
//   verification, score contribution, "update available", a count, a judgement strip) or a number with its
//   icon (time, tiles, BPM, clears, likes), like the website. One size and shape everywhere.
// - ValueBox: the one emphasized value of a row or a record (the value a list is sorted by, a rank, a record).

/// Small label for a category, status or number. Always [height] tall with the Material 3 small shape.
///
/// Neutral by default; with [color] the text takes that color on a faint tint of it, for labels that carry
/// meaning (allowed/declined, what a pass adds to the ranked score, an available update).
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, this.label, this.child, this.color, this.tip, this.icon, this.trailingIcon});

  static const height = 20.0;
  static const _radius = BorderRadius.all(Radius.circular(8));
  static const _padding = EdgeInsets.symmetric(horizontal: 8);

  final String? label;

  /// Content instead of [label] (several colored numbers, an icon and text, ...).
  final Widget? child;

  final Color? color;

  /// Shown on hover and keyboard focus.
  final String? tip;

  /// Small icon before the content (what a number counts: time, tiles, clears, ...).
  final IconData? icon;

  /// Small icon after the content (an info mark when there is more on hover).
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color;
    final foreground = tint ?? theme.colorScheme.onSurfaceVariant;

    // No `alignment` here: a Container with one fills all the width it may take (a whole Wrap line).
    final chip = Container(
      height: height,
      padding: _padding,
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.15) ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: _radius,
      ),
      child: DefaultTextStyle.merge(
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: tint == null ? null : FontWeight.w700,
        ),
        maxLines: 1,
        softWrap: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 4,
          children: [
            if (icon case final icon?) Icon(icon, size: 14, color: foreground),
            child ?? Text(label ?? ''),
            if (trailingIcon case final icon?) Icon(icon, size: 14, color: foreground),
          ],
        ),
      ),
    );
    final message = tip;
    return message == null ? chip : HoverTip(message: message, child: chip);
  }
}

/// The emphasized value of a row or a record: the value a list is sorted by, a rank, a record holder.
class ValueBox extends StatelessWidget {
  const ValueBox({super.key, required this.child, this.constraints});

  final Widget child;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    constraints: constraints,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
    child: child,
  );
}
