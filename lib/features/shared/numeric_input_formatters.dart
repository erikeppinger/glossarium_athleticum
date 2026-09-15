import 'package:flutter/services.dart';

/// `keyboardType: TextInputType.number`/`numberWithOptions` only chooses
/// which on-screen keyboard to show - it does nothing to stop a physical or
/// Bluetooth keyboard, autofill, or a paste from putting arbitrary text into
/// the field. Every numeric-only field in this app fed that text straight
/// into `int.tryParse`/`double.tryParse`, which silently treats anything
/// unparseable as "nothing typed" rather than rejecting it - reported live:
/// typing "test" into execution mode's Weight field logged the set with a
/// null weight and no indication anything was wrong, since the field never
/// stopped the input from being entered or shown in the first place. These
/// formatters reject the keystroke itself instead of silently discarding it
/// later.
final integerInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];

/// Digits with at most one decimal point and at most two decimal places
/// (weight, RPE, body measurements, distance) - allows an empty string so
/// backspace/clear still works. The `^...$` anchors mean
/// [FilteringTextInputFormatter.allow] rejects the whole edit whenever it
/// would produce something that doesn't match (e.g. a second '.', a third
/// decimal digit, or a letter), rather than only filtering per-character
/// (which can't enforce "only one dot total" on its own). The two-decimal
/// cap matches this app's own existing precision ceiling elsewhere
/// (`formatPlateWeight()` in `plate_calculator.dart` also stops at two) -
/// reported live (2026-09-15): nothing this app tracks (weight, RPE,
/// measurements) is ever meaningfully more precise than that, and an
/// unbounded decimal tail (e.g. pasted/autocorrected input producing
/// "90.89554545") read as a real display/data bug, not a feature.
///
/// Comma is normalized to a period before that check runs - reported live
/// (2026-09-11, Android and Windows both): many European keyboards/OS locales
/// send ',' for the numeric keypad's decimal key, which the regex above
/// doesn't accept - the whole edit was rejected and reverted, corrupting
/// whatever had already been typed (e.g. typing "12,5" silently produced
/// "125" once the rejected comma was dropped, reading as data loss). Comma
/// and period are the same length so this can't shift the cursor either.
final decimalInputFormatters = <TextInputFormatter>[
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
  ),
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
];
