import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/models/pass.dart';
import 'hover_tip.dart';

/// Judgement colors. Early and late sides share colors, getting greener toward the center (same layout as the website).
abstract final class JudgementColors {
  static const perfect = Color(0xFF6BD68A);
  static const near = Color(0xFFF2D06B);
  static const far = Color(0xFFF4A259);
  static const worst = Color(0xFFF2545B);

  /// Center Perfect of X-Perfect passes, white to stand apart from Perfect−/Perfect+ (green).
  static const xPerfect = Color(0xFFFFFFFF);

  /// Platinum for special values like the accuracy of a pure X-Perfect.
  static const platinum = Color(0xFFE6EEF6);
  static const platinumGlow = Color(0xFFA8CCE8);

  static Color of(Judgement judgement, {required bool xPerfect}) => switch (judgement) {
    Judgement.tooEarly || Judgement.tooLate => worst,
    Judgement.early || Judgement.late => far,
    Judgement.earlyPerfect || Judgement.latePerfect => near,
    Judgement.perfectMinus || Judgement.perfectPlus => perfect,
    Judgement.perfect => xPerfect ? JudgementColors.xPerfect : perfect,
  };
}

/// Flags on a pass (same order and names as the website's PassFlags):
/// world's first, auto-submitted, key count, hold setting, game version, X-Perfect.
List<({String label, String? tip})> passFlags(LevelPass pass) => [
  if (pass.isWorldsFirst) (label: 'WF', tip: l10n.worldsFirstClearBadge),
  if (pass.isWorldsFirstPP) (label: 'WF PP', tip: l10n.worldsFirstPurePerfect),
  if (pass.isAutoSubmitted) (label: l10n.autoSubmitted, tip: l10n.submittedStraightFromThe),
  if (pass.keyCountLabel case final keys?) (label: keys, tip: null),
  if (pass.isNoHoldTap) (label: l10n.noHold, tip: l10n.altHoldOption),
  if (pass.era == AdofaiEra.v2) (label: 'v2', tip: l10n.beforeTheEngineChange),
  if (pass.era == AdofaiEra.pre340) (label: '<3.4.0', tip: l10n.beforeXPerfectUp),
  if (pass.isXPerfectMode) (label: 'X-Perfect', tip: null),
];

/// One flag (a small rounded chip). Shows its description on hover if it has one.
class PassFlagChip extends StatelessWidget {
  const PassFlagChip({super.key, required this.label, this.tip, this.compact = false});

  final String label;
  final String? tip;

  /// Smaller size for tight places like leaderboard rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: compact ? theme.textTheme.labelSmall : theme.textTheme.labelLarge),
    );
    final message = tip;
    return message == null ? chip : HoverTip(message: message, child: chip);
  }
}

/// Ranked score contribution. Green is actually added, gray is what it could have added.
class ImpactChip extends StatelessWidget {
  const ImpactChip({super.key, required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF6BD68A);
    final color = positive ? green : theme.colorScheme.onSurfaceVariant;

    return HoverTip(
      message: positive ? l10n.whatThisPassAdds : l10n.doesntCountTowardThe,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
