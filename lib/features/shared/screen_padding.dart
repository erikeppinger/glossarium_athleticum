import 'package:flutter/widgets.dart';

/// Padding for a full-screen scrolling list: [base] plus room for Android's
/// navigation bar at the bottom. A Scaffold body draws behind that bar, and
/// a list given its own padding no longer adds the bar's height by itself,
/// so without this the last buttons can end up underneath it.
EdgeInsets screenListPadding(
  BuildContext context, [
  EdgeInsets base = const EdgeInsets.all(16),
]) => base + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom);
