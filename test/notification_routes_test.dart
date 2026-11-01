import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/notifications/notification_routes.dart';

void main() {
  group('où mène chaque notification', () {
    test('messages, matchs et demandes : la messagerie', () {
      expect(notificationDestination('NEW_MESSAGE'), '/chat');
      expect(notificationDestination('NEW_MATCH'), '/chat');
      expect(notificationDestination('NEW_REQUEST'), '/chat');
    });

    test('événements : la liste des événements, ou Mes événements pour l\'organisateur', () {
      expect(notificationDestination('EVENT_REMINDER'), '/events');
      expect(notificationDestination('EVENT_CROSSED'), '/events');
      expect(notificationDestination('WAITLIST_PROMOTED'), '/events');
      expect(notificationDestination('NEW_ATTENDEE'), '/my-events');
    });

    test('vérification de profil et demande d\'organisateur : le profil', () {
      expect(notificationDestination('VERIFICATION_APPROVED'), '/profile');
      expect(notificationDestination('VERIFICATION_REJECTED'), '/profile');
      expect(notificationDestination('ORGANIZER_APPROVED'), '/profile');
      expect(notificationDestination('ORGANIZER_REJECTED'), '/profile');
    });

    test('une nouvelle demande d\'organisateur mène les modérateurs à la modération', () {
      expect(notificationDestination('NEW_ORGANIZER_REQUEST'), '/moderation');
    });

    test('un type inconnu (serveur plus récent) mène à la messagerie plutôt que nulle part', () {
      expect(notificationDestination('QUELQUE_CHOSE_DE_NOUVEAU'), '/chat');
    });
  });
}
