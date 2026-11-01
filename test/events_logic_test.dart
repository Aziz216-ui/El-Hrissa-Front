// Règles d'affichage des événements : que peut-on faire de chacun ?

import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/models/event_models.dart';
import 'package:el_hrissa_front/features/events/events_screen.dart';
import 'package:el_hrissa_front/shared/utils/link_opener.dart';

EventResponse event({String? url, int? creator, String? venue, String? city}) => EventResponse.fromJson({
      'id': 1,
      'name': 'Test',
      'sourceUrl': url,
      'createdByUserId': creator,
      'venueName': venue,
      'city': city,
      'attendeeCount': 0,
    });

void main() {
  group('action', () {
    test('un lien de réservation ouvre la billetterie', () {
      expect(event(url: 'https://exemple.tn/billets/1').action, EventAction.book);
    });

    test('un événement créé dans l\'app se réserve dans l\'app', () {
      expect(event(creator: 7).action, EventAction.register);
    });

    test('sans lien ni organisateur, ce n\'est qu\'une suggestion', () {
      expect(event().action, EventAction.suggestion);
      expect(event(url: '   ').action, EventAction.suggestion);
    });

    test('le lien l\'emporte sur l\'inscription dans l\'app', () {
      expect(event(url: 'https://exemple.tn', creator: 7).action, EventAction.book);
    });
  });

  group('lieu affiché', () {
    test('le lieu et la ville sont réunis', () {
      expect(eventPlaceText(event(venue: 'Palais des Congrès', city: 'Tunis')), 'Palais des Congrès, Tunis');
    });

    test('la ville n\'est pas répétée si elle est déjà dans le lieu', () {
      expect(eventPlaceText(event(venue: 'Théâtre de Tunis', city: 'tunis')), 'Théâtre de Tunis');
    });

    test('à défaut de lieu, on affiche la ville', () {
      expect(eventPlaceText(event(city: 'Sousse')), 'Sousse');
      expect(eventPlaceText(event()), '');
    });
  });

  group('liens externes', () {
    test('seuls http et https sont acceptés', () async {
      expect(await openExternalLink('javascript:alert(1)'), isFalse);
      expect(await openExternalLink('intent://scan/#Intent;end'), isFalse);
      expect(await openExternalLink('file:///etc/passwd'), isFalse);
      expect(await openExternalLink('pas une adresse'), isFalse);
      expect(await openExternalLink(''), isFalse);
    });
  });

  test('les types inconnus gardent leur code', () {
    expect(eventCategoryLabel('THEATRE'), 'Théâtre');
    expect(eventCategoryLabel('NOUVEAU'), 'NOUVEAU');
  });

  group("places et liste d'attente", () {
    EventResponse withCapacity(int? capacity, int? left, {DateTime? starts, DateTime? ends}) => EventResponse.fromJson({
          'id': 1,
          'name': 'Sortie',
          'attendeeCount': (capacity ?? 0) - (left ?? 0),
          'capacity': capacity,
          'spotsLeft': left,
          'startsAt': starts?.toUtc().toIso8601String(),
          'endsAt': ends?.toUtc().toIso8601String(),
        });

    test("un événement sans limite n'est jamais complet", () {
      expect(withCapacity(null, null).isFull, isFalse);
    });

    test('il est complet quand il ne reste aucune place', () {
      expect(withCapacity(10, 0).isFull, isTrue);
      expect(withCapacity(10, 3).isFull, isFalse);
    });

    test("il est terminé 4 h après son début s'il n'a pas d'heure de fin", () {
      final now = DateTime.now();
      expect(withCapacity(null, null, starts: now.subtract(const Duration(hours: 5))).hasEnded, isTrue);
      expect(withCapacity(null, null, starts: now.subtract(const Duration(hours: 2))).hasEnded, isFalse);
      expect(withCapacity(null, null, starts: now.subtract(const Duration(hours: 9)), ends: now.add(const Duration(hours: 1))).hasEnded, isFalse);
      expect(withCapacity(null, null).hasEnded, isFalse);
    });

    test('un ancien serveur sans ces champs reste compris', () {
      final e = EventResponse.fromJson({'id': 2, 'name': 'Ancien', 'attendeeCount': 4});
      expect(e.capacity, isNull);
      expect(e.isFull, isFalse);
      expect(e.waitlistCount, isNull);
    });
  });

  test('la page organisateur est lue telle que le serveur la renvoie', () {
    final o = OrganizerResponse.fromJson({
      'userId': 7,
      'displayName': 'Club S.',
      'eventsCount': 3,
      'participantsCount': 41,
      'upcomingEvents': [
        {'id': 1, 'name': 'Soirée', 'attendeeCount': 12, 'capacity': 20, 'spotsLeft': 8}
      ],
    });
    expect(o.displayName, 'Club S.');
    expect(o.participantsCount, 41);
    expect(o.upcomingEvents.single.spotsLeft, 8);
  });
}
