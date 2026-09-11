/// Standard Olympic plate sizes, heaviest first - the order this list is in
/// is what `calculatePlateLoad`'s greedy algorithm relies on.
const standardPlatesKg = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// US/Imperial plate sizes, heaviest first.
const standardPlatesLbs = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

/// Like `formatWeightNumber` (`lib/logic/units.dart`), but keeps up to two
/// decimal places instead of one. That function's single-decimal rounding
/// is fine for everyday logged weights (never fine-grained enough to need a
/// second decimal), but a standard 1.25kg "quarter" plate - or any odd
/// custom size someone adds - would otherwise display as a materially
/// wrong "1.3". Scoped to this file rather than changing the shared
/// formatter everywhere, since this precision need is specific to plates.
String formatPlateWeight(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) return value.toInt().toString();
  var text = value.toStringAsFixed(2);
  if (text.endsWith('0')) text = text.substring(0, text.length - 1);
  return text;
}

class PlateCount {
  final double size;
  final int count;

  const PlateCount({required this.size, required this.count});

  @override
  bool operator ==(Object other) =>
      other is PlateCount && other.size == size && other.count == count;

  @override
  int get hashCode => Object.hash(size, count);

  @override
  String toString() => 'PlateCount(size: $size, count: $count)';
}

class PlateLoadResult {
  /// One entry per plate size actually used, heaviest first - a size with
  /// zero count is never included.
  final List<PlateCount> platesPerSide;

  /// The bar weight plus every loaded plate on both sides - may be less
  /// than [targetWeight] if the available plates can't reach it exactly.
  final double loadedWeight;

  /// `targetWeight - loadedWeight`, always >= 0. Zero means an exact fit.
  final double shortfall;

  const PlateLoadResult({
    required this.platesPerSide,
    required this.loadedWeight,
    required this.shortfall,
  });
}

/// Greedy largest-plate-first per side. Correct (finds the closest
/// reachable weight, using the fewest plates) for the two canonical plate
/// sets above, since each is a "canonical coin system" where every
/// denomination divides evenly into a small number of the next size up -
/// not proven optimal for an arbitrary custom plate set, which this
/// version doesn't offer.
PlateLoadResult calculatePlateLoad({
  required double targetWeight,
  required double barWeight,
  List<double> availablePlates = standardPlatesKg,
}) {
  final perSideTarget = targetWeight <= barWeight
      ? 0.0
      : (targetWeight - barWeight) / 2;

  var remaining = perSideTarget;
  final plates = <PlateCount>[];
  for (final size in availablePlates) {
    if (size <= 0) continue;
    final count = (remaining / size).floor();
    if (count > 0) {
      plates.add(PlateCount(size: size, count: count));
      remaining -= size * count;
    }
  }

  final perSideLoaded = perSideTarget - remaining;
  final loadedWeight = barWeight + perSideLoaded * 2;
  return PlateLoadResult(
    platesPerSide: plates,
    loadedWeight: loadedWeight,
    shortfall: (targetWeight - loadedWeight).clamp(0, double.infinity),
  );
}
