import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academia_app/app.dart';

void main() {
  testWidgets('tela inicial exige e-mail e senha', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AcademiaApp(fontesOnline: false));
    await tester.pumpAndSettle();
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0),
      'ana@exemplo.test');
    await tester.enterText(find.byType(TextFormField).at(1),
      'Admin@2026!');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Visão geral'), findsOneWidget);
  });
}
