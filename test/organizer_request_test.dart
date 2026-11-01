import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/core/auth/auth_state.dart';
import 'package:el_hrissa_front/core/models/organizer_request_models.dart';

void main() {
  group('demande d\'organisateur', () {
    test('une demande en cours est reconnue', () {
      final info = OrganizerRequestInfo.fromJson({'status': 'PENDING', 'organizationName': 'Club', 'role': 'user'});
      expect(info.isPending, isTrue);
      expect(info.isRejected, isFalse);
      expect(info.role, 'user');
    });

    test('une demande refusée garde son motif', () {
      final info = OrganizerRequestInfo.fromJson({'status': 'REJECTED', 'rejectReason': 'Lien manquant'});
      expect(info.isRejected, isTrue);
      expect(info.rejectReason, 'Lien manquant');
    });

    test('sans demande, le serveur renvoie NONE (ou rien)', () {
      expect(OrganizerRequestInfo.fromJson({'status': 'NONE', 'role': 'user'}).isNone, isTrue);
      expect(OrganizerRequestInfo.fromJson({}).isNone, isTrue);
    });

    test('une demande vue par un modérateur est lue en entier', () {
      final item = OrganizerRequestItem.fromJson({
        'id': 4,
        'userName': 'Karim Ben',
        'email': 'k@x.tn',
        'organizationName': 'Club Sidi',
        'phone': '20123456',
        'link': 'https://instagram.com/club',
        'description': 'Soirées et sorties',
        'submittedAt': '2026-11-01T10:00:00Z',
      });
      expect(item.organizationName, 'Club Sidi');
      expect(item.link, 'https://instagram.com/club');
      expect(item.submittedAt, isNotNull);
    });
  });

  group('rôles dans l\'app', () {
    test('un visiteur ne crée pas d\'événements et ne modère pas', () {
      AuthState.instance.setLoggedIn(role: 'user');
      expect(AuthState.instance.canCreateEvents, isFalse);
      expect(AuthState.instance.canModerate, isFalse);
    });

    test('un organisateur crée des événements mais ne modère pas', () {
      AuthState.instance.setLoggedIn(role: 'organisateur');
      expect(AuthState.instance.canCreateEvents, isTrue);
      expect(AuthState.instance.canModerate, isFalse);
    });

    test('un modérateur fait les deux', () {
      AuthState.instance.setLoggedIn(role: 'moderateur');
      expect(AuthState.instance.canCreateEvents, isTrue);
      expect(AuthState.instance.canModerate, isTrue);
    });

    test('un rôle accordé par une demande acceptée est pris en compte sans reconnexion', () {
      AuthState.instance.setLoggedIn(role: 'user');
      AuthState.instance.setRole('organisateur');
      expect(AuthState.instance.canCreateEvents, isTrue);
    });
  });
}
