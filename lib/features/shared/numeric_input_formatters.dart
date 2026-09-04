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

/// Digits with at most one decimal point (weight, RPE, body measurements,
/// distance) - allows an empty string so backspace/clear still works. The
/// `^...$` anchors mean [FilteringTextInputFormatter.allow] rejects the
/// whole edit whenever it would produce something that doesn't match
/// (e.g. a second '.' or a letter), rather than only filtering per-character
/// (which can't enforce "only one dot total" on its own).
final decimalInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
];
