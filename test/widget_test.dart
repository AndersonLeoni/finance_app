import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/main.dart';

void main() {
  testWidgets('App carrega com navegacao inferior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinanceApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Contas'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Renda'), findsOneWidget);
    expect(find.text('Projetos'), findsOneWidget);
  });
}
