// L'inscription propose « Visiteur » ou « Organisateur » ; ce dernier ajoute les champs de la demande,
// sans débordement sur un petit téléphone.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/theme/app_theme.dart';
import 'package:el_hrissa_front/features/auth/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Choisir « Organisateur » affiche la demande, sans débordement", (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const RegisterScreen()));
    await tester.pump(const Duration(milliseconds: 700));

    // Par défaut : visiteur, aucun champ de demande
    expect(find.text('Visiteur'), findsOneWidget);
    expect(find.text('Organisateur'), findsOneWidget);
    expect(find.text("Nom de l'organisation ou du club"), findsNothing);

    await tester.tap(find.text('Organisateur'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Nom de l'organisation ou du club"), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.textContaining('Un modérateur examine votre demande'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Revenir à « Visiteur » masque les champs
    await tester.tap(find.text('Visiteur'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Nom de l'organisation ou du club"), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
