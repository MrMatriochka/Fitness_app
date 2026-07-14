import 'package:fitness_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le thème accepte un FilledButton dans une Row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: Text('Forme du jour')),
              FilledButton(
                onPressed: () {},
                child: const Text('Évaluer'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Évaluer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
