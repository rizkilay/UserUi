import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/screens/cotisation/views/cotisation_screen.dart';

void main() {
  testWidgets('CotisationScreen displays statistics and transactions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CotisationScreen()));

    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.text('Transactions totales'), findsOneWidget);
    expect(find.text('1 050 550 Fcfa'), findsOneWidget);
    expect(find.text('Mes transactions'), findsOneWidget);
    expect(find.text('payer'), findsOneWidget);
  });
}
