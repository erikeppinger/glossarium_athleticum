import 'package:flutter/material.dart';

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
///
/// Colour is never the only signal anywhere in the app - the muscle-group
/// name is always shown as text next to it - so a palette that is hard for
/// a given person to separate degrades gracefully rather than hiding data.
enum AppColorPalette { pastel, okabeIto, tolMuted, monochrome }

extension AppColorPaletteLabel on AppColorPalette {
  String get label => switch (this) {
    AppColorPalette.pastel => 'Pastel (default)',
    AppColorPalette.okabeIto => 'Okabe–Ito (colour-blind safe)',
    AppColorPalette.tolMuted => 'Tol muted (colour-blind safe)',
    AppColorPalette.monochrome => 'Monochrome (no hue coding)',
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
