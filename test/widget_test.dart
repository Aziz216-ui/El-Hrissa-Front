// Smoke test : sans session, l'app doit rediriger vers l'écran d'accueil (garde d'authentification),
// qui propose de créer un compte ou de se connecter, et ne plus proposer de « mode démo ».

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/auth/auth_state.dart';
import 'package:el_hrissa_front/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Sans token, l\'app affiche l\'accueil', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AuthState.instance.init();

    await tester.pumpWidget(const ElHrissaApp());
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.textContaining('Mode Découverte'), findsNothing);

    // Les textes légaux sont accessibles depuis l'accueil
    await tester.tap(find.text("Conditions d'utilisation"));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dernière mise à jour'), findsOneWidget);
    expect(find.text('Qui peut utiliser Elahrisa'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);

    // « Se connecter » mène à la connexion
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsWidgets);
  });
}
