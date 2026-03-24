import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/screens/cotisation/views/cotisation_screen.dart';

void main() {
  testWidgets('CotisationScreen displays statistics and transactions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CotisationScreen()));

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Montant disponible'), findsOneWidget);
    expect(find.text('1 050 Fcfa'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Retirer'), findsOneWidget);
  });
}
