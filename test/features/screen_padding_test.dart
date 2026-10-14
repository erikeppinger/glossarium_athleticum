import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/shared/screen_padding.dart';

void main() {
  testWidgets('adds the navigation bar height to the bottom only', (
    tester,
  ) async {
    late EdgeInsets padding;
    late EdgeInsets custom;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
        child: Builder(
          builder: (context) {
            padding = screenListPadding(context);
            custom = screenListPadding(
              context,
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 64));
    expect(custom, const EdgeInsets.fromLTRB(16, 0, 16, 64));
  });
}
