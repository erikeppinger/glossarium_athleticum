import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/shared/linked_text.dart';

// Exercise descriptions can point to a video or, for the wger.de starter
// library, to the exercise's page there (which often has pictures).
void main() {
  test('splits out web links, leaving trailing punctuation as text', () {
    expect(
      splitLinks(
        'Hinge at the hips.\nOn wger.de: https://wger.de/en/exercise/9/view-base',
      ),
      [
        (text: 'Hinge at the hips.\nOn wger.de: ', isLink: false),
        (text: 'https://wger.de/en/exercise/9/view-base', isLink: true),
      ],
    );
    expect(splitLinks('See https://example.com/a. Then rest.'), [
      (text: 'See ', isLink: false),
      (text: 'https://example.com/a', isLink: true),
      (text: '. Then rest.', isLink: false),
    ]);
    expect(splitLinks('No links here'), [
      (text: 'No links here', isLink: false),
    ]);
  });

  testWidgets('a link in the text is tappable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LinkedText('Pictures: https://wger.de/en/exercise/9/view-base'),
        ),
      ),
    );

    final rich = tester.widget<RichText>(find.byType(RichText).last);
    final spans = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final link = spans.singleWhere((s) => s.recognizer != null);
    expect(link.text, 'https://wger.de/en/exercise/9/view-base');
    expect(link.recognizer, isA<TapGestureRecognizer>());
    expect(spans.first.recognizer, isNull);
  });
}
