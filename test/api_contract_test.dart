// Test de contrat : exécute les VRAIS services Flutter contre un backend local
// pour vérifier que les modèles Dart lisent bien les réponses du serveur.
//
// Prérequis : backend démarré sur http://localhost:8086 (base vide ou non).
// Lancement :
//   flutter test test/api_contract_test.dart --dart-define=API_BASE_URL=http://localhost:8086
//
// Sans backend joignable, le test est ignoré (skip) au lieu d'échouer.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:el_hrissa_front/core/api/api_client.dart';
import 'package:el_hrissa_front/core/api/endpoints.dart';
import 'package:el_hrissa_front/core/auth/auth_state.dart';
import 'package:el_hrissa_front/core/services/auth_service.dart';
import 'package:el_hrissa_front/core/services/event_service.dart';
import 'package:el_hrissa_front/core/services/message_service.dart';
import 'package:el_hrissa_front/core/services/notification_service.dart';
import 'package:el_hrissa_front/core/services/profile_service.dart';
import 'package:el_hrissa_front/core/services/safety_service.dart';
import 'package:el_hrissa_front/core/services/swipe_service.dart';

// PNG 1x1 valide
final _png = [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, 0x0d, 0x49,
  0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0xf8, 0xcf, 0xc0, 0xf0, 0x1f, 0x00, 0x05, 0x00, 0x02, 0x01, 0xa5, 0xf6, 0x45,
  0x40, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
];

Future<bool> _backendUp() async {
  try {
    final r = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)))
        .get('${Endpoints.baseUrl}/actuator/health');
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Crée un utilisateur complet (profil + photo + position) et renvoie son id et son token.
Future<({int id, String token})> _signup(String tag, String gender, {String role = 'USER'}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final auth = await AuthService().register(
    cin: stamp % 90000000 + 10000000,
    nom: 'Test$tag',
    prenom: 'User$tag',
    dateNaissance: '1998-05-10',
    gender: gender,
    email: '${tag}_$stamp@contract.tn',
    password: 'Passw0rd!',
    role: role,
  );
  return (id: auth.user.id!, token: auth.token);
}

Future<void> _fillProfile(String name) async {
  final profiles = ProfileService();
  await profiles.updateProfile(
    displayName: name,
    bio: 'Bio de $name',
    genderPreference: 'EVERYONE',
    interests: ['Cinéma', 'Voyage'],
  );
  await profiles.updateLocation(36.8065, 10.1815);
  await profiles.uploadPhoto(XFile.fromData(
    Uint8List.fromList(_png),
    name: 'photo.png',
    mimeType: 'image/png',
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // autorise les vraies requêtes réseau dans flutter test

  test('Parcours complet contre le vrai backend', () async {
    if (!await _backendUp()) {
      markTestSkipped('Backend injoignable sur ${Endpoints.baseUrl}');
      return;
    }

    // --- Inscription : l'id utilisateur doit être lu ("idClient") et stocké
    final a = await _signup('a', 'MEN');
    expect(a.id, greaterThan(0), reason: 'UserResponse doit lire idClient');
    expect(await AuthService().getCurrentUserId(), a.id);
    expect(AuthState.instance.loggedIn, isTrue);
    await _fillProfile('Alice');

    final myProfile = await ProfileService().getMyProfile();
    expect(myProfile.displayName, 'Alice');
    expect(myProfile.photos, hasLength(1));
    expect(myProfile.photos.first.isMain, isTrue, reason: 'PhotoResponse doit lire "main"');
    expect(myProfile.photos.first.url, startsWith('http'), reason: 'URL de photo rendue absolue');
    expect(myProfile.complete, isTrue);
    expect(myProfile.hasLocation, isTrue);
    expect(myProfile.interests, containsAll(['Cinéma', 'Voyage']));

    // La photo uploadée est réellement servie
    final photo = await Dio().get<List<int>>(myProfile.photos.first.url,
        options: Options(responseType: ResponseType.bytes));
    expect(photo.statusCode, 200);

    // --- Deuxième utilisateur
    final b = await _signup('b', 'WOMEN');
    await _fillProfile('Bella');

    // --- Candidats : B doit apparaître, avec distance
    final candidates = await SwipeService().getCandidates();
    expect(candidates.map((c) => c.profile.userId), contains(a.id));
    final candA = candidates.firstWhere((c) => c.profile.userId == a.id);
    expect(candA.distanceKm, isNotNull);
    expect(candA.profile.mainPhotoUrl, isNotNull);

    // --- Swipe de B vers A, puis de A vers B => match
    final first = await SwipeService().swipe(a.id, true);
    expect(first.matched, isFalse);

    // Reconnexion en tant que A
    final loginA = await AuthService().login(
      (await _emailOf(a.token)) ?? '',
      'Passw0rd!',
    );
    expect(loginA.user.id, a.id, reason: 'login doit aussi lire idClient');
    final second = await SwipeService().swipe(b.id, true);
    expect(second.matched, isTrue);
    expect(second.matchId, isNotNull);

    final matches = await SwipeService().getMyMatches();
    expect(matches.single.profile.userId, b.id);
    final matchId = matches.single.matchId;

    // --- Messages : le plus récent en premier
    final msgs = MessageService();
    await msgs.sendMessage(matchId, 'Premier');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await msgs.sendMessage(matchId, 'Deuxième');
    final list = await msgs.getMessages(matchId);
    expect(list.map((m) => m.content).toList(), ['Deuxième', 'Premier']);
    expect(list.first.senderId, a.id);

    // --- Notifications
    final notifs = NotificationService();
    expect(await notifs.getUnreadCount(), greaterThanOrEqualTo(1));
    final items = await notifs.getNotifications();
    expect(items, isNotEmpty);
    await notifs.markAllRead();
    expect(await notifs.getUnreadCount(), 0);

    // --- Événements (organisateur)
    final org = await _signup('o', 'MEN', role: 'ORGANISATEUR');
    expect(org.id, greaterThan(0));
    expect(AuthState.instance.isOrganizer, isTrue);
    final events = EventService();
    final created = await events.createEvent(
      name: 'Jazz contract',
      venueName: 'Gammarth',
      startsAt: DateTime.now().add(const Duration(days: 3)),
    );
    expect(created.id, greaterThan(0));

    // Utilisateur simple : rejoint puis quitte
    await _signup('c', 'WOMEN');
    expect((await events.getEvents()).map((e) => e.id), contains(created.id));
    expect(await events.getJoinedEventIds(), isEmpty);
    await events.joinEvent(created.id);
    expect(await events.getJoinedEventIds(), contains(created.id));
    // Sans profil créé, le participant est ignoré mais la liste ne plante pas
    expect(await events.getAttendees(created.id), isEmpty);
    await ProfileService().getMyProfile(); // crée le profil à la demande
    expect(await events.getAttendees(created.id), hasLength(1));
    await events.leaveEvent(created.id);
    expect(await events.getJoinedEventIds(), isEmpty);

    // --- Blocage / signalement
    final safety = SafetyService();
    await safety.report(org.id, 'SPAM', details: 'test');
    await safety.block(org.id);
    expect((await safety.getBlocked()).map((u) => u.userId), contains(org.id));
    await safety.unblock(org.id);
    expect(await safety.getBlocked(), isEmpty);

    // --- Déconnexion
    await AuthService().logout();
    expect(AuthState.instance.loggedIn, isFalse);
    expect(await ApiClient().hasToken(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test("Mot de passe oublié, état de l'email et suppression de compte", () async {
    if (!await _backendUp()) {
      markTestSkipped('Backend injoignable sur ${Endpoints.baseUrl}');
      return;
    }
    final u = await _signup('d', 'WOMEN');
    final email = (await _emailOf(u.token))!;

    // Un compte neuf n'a pas encore vérifié son email
    expect((await ProfileService().getMyProfile()).emailVerified, isFalse);

    // Même réponse (succès) que l'adresse existe ou non : pas de fuite sur les comptes inscrits
    await AuthService().forgotPassword(email);
    await AuthService().forgotPassword('personne-${DateTime.now().microsecondsSinceEpoch}@contract.tn');

    // Suppression définitive : déconnexion, puis le compte n'existe plus
    await _fillProfile('Dora');
    await AuthService().deleteMyAccount();
    expect(AuthState.instance.loggedIn, isFalse);
    expect(await ApiClient().hasToken(), isFalse);
    await expectLater(
      AuthService().login(email, 'Passw0rd!'),
      throwsA(predicate((e) => e.toString().contains('incorrect'))),
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('Une erreur serveur est traduite en message lisible', () async {
    if (!await _backendUp()) {
      markTestSkipped('Backend injoignable');
      return;
    }
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(
      AuthService().login('inconnu@contract.tn', 'mauvais'),
      throwsA(predicate((e) => e.toString().contains('incorrect'))),
    );
  });
}

/// Décode l'email du JWT (claim "sub").
Future<String?> _emailOf(String token) async {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
  while (payload.length % 4 != 0) {
    payload += '=';
  }
  final json = String.fromCharCodes(const Base64Decoder().convert(payload));
  final m = RegExp(r'"sub":"([^"]+)"').firstMatch(json);
  return m?.group(1);
}
