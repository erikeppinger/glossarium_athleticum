import 'package:flutter/material.dart';

import '../data/app_database.dart' show Exercise;

/// The broad training areas the app colour-codes by. Deliberately few and
/// coarse: a palette stops being distinguishable somewhere around 8-9 hues
/// even for people with typical colour vision, and far sooner for people
/// with a colour vision deficiency.
enum MuscleArea {
  legs,
  chest,
  back,
  shoulders,
  arms,
  core,
  cardio,
  fullBody,
  other,
}

extension MuscleAreaLabel on MuscleArea {
  String get label => switch (this) {
    MuscleArea.legs => 'Legs',
    MuscleArea.chest => 'Chest',
    MuscleArea.back => 'Back',
    MuscleArea.shoulders => 'Shoulders',
    MuscleArea.arms => 'Arms',
    MuscleArea.core => 'Core',
    MuscleArea.cardio => 'Cardio',
    MuscleArea.fullBody => 'Full body',
    MuscleArea.other => 'Other',
  };
}

/// Selectable colour palettes.
///
/// The non-default options are established, research-backed schemes rather
/// than hand-picked colours:
///
/// * [ColorScheme_.okabeIto] - Okabe & Ito (2008), the most widely cited
///   qualitative palette designed to stay distinguishable under protanopia,
///   deuteranopia and tritanopia simultaneously.
/// * [ColorScheme_.tolMuted] - Paul Tol's "muted" qualitative scheme, also
///   colour-vision-deficiency safe and lower in saturation, which suits long
///   reading sessions better than a bright scheme.
/// * [ColorScheme_.monochrome] - for achromatopsia, and for anyone who finds
///   hue coding noisy: distinguishes purely by lightness.
/// * [ColorScheme_.viridis] - matplotlib's Viridis, designed by Stéfan van
///   der Walt and Nathaniel Smith to be perceptually uniform (equal steps in
///   the data look equally different) and to stay legible under every
///   common colour vision deficiency and in greyscale printouts - a popular
///   alternative to Okabe-Ito/Tol for people who find their hues too close
///   to typical "warning" reds/oranges.
///
/// Colour is never the only signal anywhere in the app - the muscle-group
/// name is always shown as text next to it - so a palette that is hard for
/// a given person to separate degrades gracefully rather than hiding data.
enum AppColorPalette { pastel, okabeIto, tolMuted, monochrome, viridis }

extension AppColorPaletteLabel on AppColorPalette {
  String get label => switch (this) {
    AppColorPalette.pastel => 'Pastel (default)',
    AppColorPalette.okabeIto => 'Okabe–Ito (colour-blind safe)',
    AppColorPalette.tolMuted => 'Tol muted (colour-blind safe)',
    AppColorPalette.monochrome => 'Monochrome (no hue coding)',
    AppColorPalette.viridis => 'Viridis (colour-blind safe)',
  };

  String get description => switch (this) {
    AppColorPalette.pastel =>
      'Soft, low-saturation hues that are easy on the eyes.',
    AppColorPalette.okabeIto =>
      'Designed to stay distinguishable with red-green and blue-yellow '
          'colour vision deficiency.',
    AppColorPalette.tolMuted =>
      'A colour-blind-safe scheme with lower saturation than Okabe–Ito.',
    AppColorPalette.monochrome =>
      'Distinguishes areas by lightness only - no hue coding at all.',
    AppColorPalette.viridis =>
      'A perceptually-uniform blue-to-yellow scale, popular in scientific '
          'charts - colour-blind safe and legible in greyscale too.',
  };
}

// Okabe & Ito (2008), "Color Universal Design" - the canonical CUD set.
const _okabeItoColors = {
  MuscleArea.legs: Color(0xFF0072B2), // blue
  MuscleArea.chest: Color(0xFFD55E00), // vermillion
  MuscleArea.back: Color(0xFF009E73), // bluish green
  MuscleArea.shoulders: Color(0xFF56B4E9), // sky blue
  MuscleArea.arms: Color(0xFFCC79A7), // reddish purple
  MuscleArea.core: Color(0xFFE69F00), // orange
  MuscleArea.cardio: Color(0xFFF0E442), // yellow
  MuscleArea.fullBody: Color(0xFF000000), // black
  MuscleArea.other: Color(0xFF999999),
};

// Paul Tol, "Colour Schemes" technical note (SRON) - the "muted" qualitative
// scheme, which is CVD-safe and gentler than the bright variants.
const _tolMutedColors = {
  MuscleArea.legs: Color(0xFF332288), // indigo
  MuscleArea.chest: Color(0xFFCC6677), // rose
  MuscleArea.back: Color(0xFF117733), // green
  MuscleArea.shoulders: Color(0xFF88CCEE), // cyan
  MuscleArea.arms: Color(0xFFAA4499), // purple
  MuscleArea.core: Color(0xFFDDCC77), // sand
  MuscleArea.cardio: Color(0xFF999933), // olive
  MuscleArea.fullBody: Color(0xFF882255), // wine
  MuscleArea.other: Color(0xFFBBBBBB),
};

const _pastelColors = {
  MuscleArea.legs: Color(0xFFA8C8E8),
  MuscleArea.chest: Color(0xFFF2B8A2),
  MuscleArea.back: Color(0xFFA8D8C0),
  MuscleArea.shoulders: Color(0xFFBFD7EA),
  MuscleArea.arms: Color(0xFFE0B8D8),
  MuscleArea.core: Color(0xFFF5D6A0),
  MuscleArea.cardio: Color(0xFFF0E6A8),
  MuscleArea.fullBody: Color(0xFFC9BFE0),
  MuscleArea.other: Color(0xFFD6D6D6),
};

// matplotlib's Viridis, sampled at 9 evenly-spaced stops across the full
// range (dark purple -> teal -> yellow) - the canonical, widely-reproduced
// values for this colormap.
const _viridisColors = {
  MuscleArea.legs: Color(0xFF440154),
  MuscleArea.chest: Color(0xFF482878),
  MuscleArea.back: Color(0xFF3E4A89),
  MuscleArea.shoulders: Color(0xFF31688E),
  MuscleArea.arms: Color(0xFF26828E),
  MuscleArea.core: Color(0xFF1F9E89),
  MuscleArea.cardio: Color(0xFF6DCD59),
  MuscleArea.fullBody: Color(0xFFB4DE2C),
  MuscleArea.other: Color(0xFFFDE725),
};

// Lightness ladder, no hue. Ordered so adjacent areas differ noticeably.
const _monochromeColors = {
  MuscleArea.legs: Color(0xFF2E2E2E),
  MuscleArea.chest: Color(0xFF9E9E9E),
  MuscleArea.back: Color(0xFF4F4F4F),
  MuscleArea.shoulders: Color(0xFFBDBDBD),
  MuscleArea.arms: Color(0xFF6E6E6E),
  MuscleArea.core: Color(0xFFD6D6D6),
  MuscleArea.cardio: Color(0xFF8A8A8A),
  MuscleArea.fullBody: Color(0xFF3D3D3D),
  MuscleArea.other: Color(0xFFE0E0E0),
};

Color colorForArea(MuscleArea area, AppColorPalette palette) {
  final map = switch (palette) {
    AppColorPalette.pastel => _pastelColors,
    AppColorPalette.okabeIto => _okabeItoColors,
    AppColorPalette.tolMuted => _tolMutedColors,
    AppColorPalette.monochrome => _monochromeColors,
    AppColorPalette.viridis => _viridisColors,
  };
  return map[area]!;
}

/// Maps an exercise's free-text muscle groups / category / movement pattern
/// onto one broad [MuscleArea].
///
/// The seed library and user-imported plans both use free text here (e.g.
/// "Posterior Chain, Back", "Quads", "Beine"), so this is keyword matching,
/// not a lookup. Order matters: more specific terms are checked before
/// broader ones, and legs before back so "posterior chain" doesn't get
/// claimed by a stray "back" substring.
MuscleArea areaForExercise({
  String muscleGroups = '',
  String category = '',
  String movementPattern = '',
}) {
  final haystack = '$muscleGroups $category $movementPattern'.toLowerCase();

  bool has(List<String> terms) => terms.any(haystack.contains);

  if (has(['cardio', 'conditioning', 'run', 'row erg', 'bike', 'sled'])) {
    return MuscleArea.cardio;
  }
  if (has([
    'quad',
    'hamstring',
    'glute',
    'calf',
    'calve',
    'leg',
    'squat',
    'posterior chain',
    'adductor',
    'abductor',
    'beine',
    'waden',
  ])) {
    return MuscleArea.legs;
  }
  if (has(['chest', 'pec', 'brust'])) return MuscleArea.chest;
  if (has(['lat', 'back', 'trap', 'rhomboid', 'pull', 'row', 'rücken'])) {
    return MuscleArea.back;
  }
  if (has(['delt', 'shoulder', 'rotator cuff', 'schulter', 'press'])) {
    return MuscleArea.shoulders;
  }
  if (has(['bicep', 'tricep', 'forearm', 'grip', 'arm', 'curl'])) {
    return MuscleArea.arms;
  }
  if (has(['core', 'ab', 'oblique', 'bauch'])) return MuscleArea.core;
  if (has(['full body', 'total body', 'ganzkörper'])) {
    return MuscleArea.fullBody;
  }
  return MuscleArea.other;
}

/// Where an exercise came from - the second colour bar in the library list,
/// alongside [MuscleArea]'s muscle-group bar. Every custom exercise used to
/// render only a muscle-area stripe like seed exercises do; when its muscle
/// groups were left blank (common - it's an optional field on the create
/// form) that stripe fell back to [MuscleArea.other]'s neutral grey with
/// nothing else to distinguish it, which read as "all my own exercises are
/// grey" even though plenty of seed exercises are also grey for the same
/// reason. A dedicated provenance bar answers a different question
/// (who made this) than the muscle bar (what does it train), so the two
/// don't compete for the same signal.
enum ExerciseProvenance { library, own, fromPlan, byAuthor }

extension ExerciseProvenanceLabel on ExerciseProvenance {
  String get label => switch (this) {
    ExerciseProvenance.library => 'Library exercise',
    ExerciseProvenance.own => 'Your own exercise',
    ExerciseProvenance.fromPlan => 'Added from an imported plan',
    ExerciseProvenance.byAuthor => 'Custom, with an author credited',
  };
}

/// Fixed, palette-independent colours (reusing Okabe-Ito hues, so they're
/// colour-vision-deficiency-safe regardless of which [AppColorPalette] the
/// muscle-area bar is currently using) - the two bars carry different kinds
/// of information, so intentionally don't share a palette selector.
const _provenanceColors = {
  ExerciseProvenance.library: Color(0xFF0072B2), // blue
  ExerciseProvenance.own: Color(0xFFE69F00), // orange
  ExerciseProvenance.fromPlan: Color(0xFF009E73), // bluish green
  ExerciseProvenance.byAuthor: Color(0xFFCC79A7), // reddish purple
};

Color colorForProvenance(ExerciseProvenance provenance) =>
    _provenanceColors[provenance]!;

ExerciseProvenance provenanceForExercise(Exercise exercise) {
  if (!exercise.isCustom) return ExerciseProvenance.library;
  if (exercise.sourcePlanName != null) return ExerciseProvenance.fromPlan;
  if (exercise.author != null) return ExerciseProvenance.byAuthor;
  return ExerciseProvenance.own;
}

// Same 9 Okabe-Ito hues as _okabeItoColors, reused here as a plain list
// rather than a second hard-coded palette - colorForCreatorValue just needs
// a qualitative, CVD-safe set to hash into, not the muscle-area mapping.
final _creatorValueColors = _okabeItoColors.values.toList(growable: false);

/// A stable colour for one *specific* plan or author name, e.g. the exercise
/// library's "Plan: `name`" / "By: `name`" filter chips.
///
/// [colorForProvenance] answers "what broad category is this from" (every
/// plan-imported exercise shares one green, regardless of which plan) - that
/// answers a different question than these filter chips ask, which is "which
/// specific plan/author is this". Sharing one colour across every distinct
/// plan defeated the entire point of colour-coding the chip row: with more
/// than one imported plan, every "Plan: ..." chip looked identical apart
/// from its text. Hashing the raw creator-filter value (e.g. "plan:Foo") to
/// a fixed hue gives each distinct plan/author its own stable colour instead
/// - reusing the Okabe-Ito set already established as this app's fixed,
/// palette-independent accessible colours, rather than a third ad-hoc one.
Color colorForCreatorValue(String value) {
  final hash = value.toLowerCase().codeUnits.fold<int>(
    0,
    (h, c) => (h * 31 + c) & 0x7fffffff,
  );
  return _creatorValueColors[hash % _creatorValueColors.length];
}
