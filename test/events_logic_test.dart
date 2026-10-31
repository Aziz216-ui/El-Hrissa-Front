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
}
