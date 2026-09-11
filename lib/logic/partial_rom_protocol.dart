/// Honest citation/explanation for the partial-range-of-motion overload
/// template (sometimes called "Neurological Carryover Training" in
/// strength-coaching blogs) - shown via an info icon next to the template
/// button in [ExercisePrescriptionFields], mirroring `progressionScienceNote`
/// and `oneRepMaxScienceNote`'s existing citation pattern.
///
/// The term traces to Paul Anderson's decades-old partial-range overload
/// method, popularized more recently by strength-coaching blogs rather than
/// peer-reviewed literature. A 2026 study in the Journal of Functional
/// Morphology and Kinesiology directly tested a progressively-increased-ROM
/// bench press protocol against traditional full-range-of-motion training
/// over 4 weeks in experienced lifters: both groups gained 1RM strength
/// equally - full-ROM training actually came out ahead on bar velocity and
/// power metrics. So the honest framing is "performs comparably to normal
/// training," not a plateau-busting secret.
const partialRomProtocolNote =
    'This template is based on a decades-old partial-range-of-motion '
    'overload method (sometimes called "Neurological Carryover Training" '
    'online), popularized by strength-coaching blogs rather than '
    'peer-reviewed research.\n\n'
    'A 2026 study in the Journal of Functional Morphology and Kinesiology '
    'directly tested it: a progressively-increased range-of-motion bench '
    'press protocol produced 1RM strength gains comparable to - not better '
    'than - normal full-range training over 4 weeks in experienced '
    'lifters. Full-range training actually came out ahead on bar velocity '
    'and power.\n\n'
    "So this isn't a proven plateau-buster - it performs about the same as "
    'training normally, with the added requirement of a rack with '
    'adjustable safety pins or chains to limit the range of motion.\n\n'
    'How it works: load 5-15% beyond your current full-range best, but '
    'move it through only a small fraction of the full range at first, '
    'then add a little more range back every 1-2 weeks.';

/// Appended to an exercise's notes when the template button is tapped -
/// instructional, not a repeat of the science note above (that's reachable
/// separately via the info icon).
const partialRomTemplateNote =
    'Partial-ROM overload template: start at a partial range of motion '
    "with the weight set below (110% of this exercise's estimated 1RM), "
    'using a rack\'s adjustable safety pins or chains to limit how far the '
    'bar travels. Add a small amount of range back every 1-2 weeks.';
