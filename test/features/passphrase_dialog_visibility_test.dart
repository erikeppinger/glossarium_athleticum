import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/settings/backup_dialogs.dart';

void main() {
  testWidgets(
    'passphrase field starts obscured and the eye icon reveals/hides it',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await promptPassphrase(
                  context,
                  title: 'Choose a backup passphrase',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hunter2');
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      final revealedField = tester.widget<TextField>(find.byType(TextField));
      expect(revealedField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Toggling back off should re-obscure it.
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(result, 'hunter2');
    },
  );
}
