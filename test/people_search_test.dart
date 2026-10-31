// Recherche d'une personne par son nom : saisie, résultats, envoi d'une demande.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/models/people_models.dart';
import 'package:el_hrissa_front/core/services/people_service.dart';
import 'package:el_hrissa_front/features/people/people_search_screen.dart';

class FakePeopleService implements PeopleService {
  final List<String> queries = [];
  final List<int> requested = [];
  List<PersonSearchResult> results;
  FakePeopleService(this.results);

  @override
  Future<List<PersonSearchResult>> search(String query) async {
    queries.add(query);
    return results;
  }

  @override
  Future<RequestResult> sendRequest(int userId) async {
    requested.add(userId);
    return const RequestResult(status: 'SENT');
  }

  @override
  Future<List<ConnectionRequest>> getRequests() async => [];

  @override
  Future<RequestResult> accept(int userId) async => const RequestResult(status: 'MATCHED', matchId: 3);

  @override
  Future<void> decline(int userId) async {}
}

Future<void> pumpScreen(WidgetTester tester, FakePeopleService service) async {
  await tester.pumpWidget(MaterialApp(home: PeopleSearchScreen(service: service)));
  await tester.pump();
}

void main() {
  const amira = PersonSearchResult(userId: 7, displayName: 'Amira B.', age: 27);

  testWidgets('avant de taper, une invitation à chercher est affichée', (tester) async {
    await pumpScreen(tester, FakePeopleService([]));

    expect(find.textContaining('Retrouvez quelqu'), findsOneWidget);
  });

  testWidgets('moins de trois lettres : aucune recherche n\'est lancée', (tester) async {
    final service = FakePeopleService([amira]);
    await pumpScreen(tester, service);

    await tester.enterText(find.byType(TextField), 'am');
    await tester.pump(const Duration(seconds: 1));

    expect(service.queries, isEmpty);
  });

  testWidgets('une recherche affiche les personnes et permet d\'envoyer une demande', (tester) async {
    final service = FakePeopleService([amira]);
    await pumpScreen(tester, service);

    await tester.enterText(find.byType(TextField), 'amira');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(service.queries, ['amira']);
    expect(find.text('Amira B., 27'), findsOneWidget);

    await tester.tap(find.text('Demander'));
    await tester.pump();
    await tester.pump();

    expect(service.requested, [7]);
    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.text('Demander'), findsNothing);
  });

  testWidgets('aucun résultat : un message explique pourquoi', (tester) async {
    await pumpScreen(tester, FakePeopleService([]));

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.textContaining('Personne trouvée'), findsOneWidget);
    expect(find.textContaining('masqués'), findsOneWidget);
  });

  testWidgets('une demande déjà envoyée ne propose plus le bouton', (tester) async {
    final service = FakePeopleService([amira.copyWith(relation: PersonRelation.requestSent)]);
    await pumpScreen(tester, service);

    await tester.enterText(find.byType(TextField), 'amira');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.text('Demander'), findsNothing);
  });

  group('modèles', () {
    test('les relations du serveur sont reconnues', () {
      expect(PersonRelation.parse('REQUEST_SENT'), PersonRelation.requestSent);
      expect(PersonRelation.parse('REQUEST_RECEIVED'), PersonRelation.requestReceived);
      expect(PersonRelation.parse('MATCHED'), PersonRelation.matched);
      expect(PersonRelation.parse('NONE'), PersonRelation.none);
      expect(PersonRelation.parse(null), PersonRelation.none);
    });

    test('une photo vide devient absente', () {
      final person = PersonSearchResult.fromJson({'userId': 1, 'displayName': 'A', 'photoUrl': ''});
      expect(person.photoUrl, isNull);
    });

    test('un match porte l\'identifiant de la conversation', () {
      final result = RequestResult.fromJson({'status': 'MATCHED', 'matchId': 12});
      expect(result.matched, isTrue);
      expect(result.matchId, 12);
    });
  });
}
