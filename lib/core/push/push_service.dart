import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../notifications/notification_routes.dart';

/// Notifications push (Firebase Cloud Messaging), Android seulement pour l'instant.
///
/// Tout est facultatif : si Firebase n'est pas disponible (site web, autre plateforme, configuration absente),
/// l'app fonctionne exactement comme avant, avec la cloche qui se met à jour toute seule.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _available = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  void Function(String route)? _navigate;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;

  bool get isAvailable => _available;

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// À appeler une fois au démarrage. N'attend rien d'important : une erreur ne bloque jamais l'app.
  Future<void> init({
    required void Function(String route) navigate,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    if (!_supported) return;
    _navigate = navigate;
    _messengerKey = messengerKey;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('Notifications push indisponibles : $e');
      return;
    }
    // Appui sur une notification quand l'app était en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    // Appui sur une notification quand l'app était fermée
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (_) {}
    // L'app est ouverte : Android n'affiche rien, on montre un petit bandeau
    FirebaseMessaging.onMessage.listen(_showInApp);
  }

  /// Après la connexion : demande l'autorisation, puis enregistre ce téléphone auprès du serveur.
  Future<void> register() async {
    if (!_available) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // getToken est marqué « déprécié » au profit d'un nouvel identifiant (FID) ; on garde le jeton classique,
      // celui que l'API d'envoi du serveur (HTTP v1, champ « token ») accepte avec certitude.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendToServer(token);
      // Firebase renouvelle parfois le jeton : le serveur doit recevoir le nouveau
      // ignore: deprecated_member_use
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(_sendToServer);
    } catch (e) {
      debugPrint('Enregistrement push impossible : $e');
    }
  }

  /// À la déconnexion : ce téléphone ne reçoit plus les notifications de ce compte.
  Future<void> unregister() async {
    final token = _token;
    if (!_available || token == null) return;
    try {
      await ApiClient().dio.delete('/api/devices', data: {'token': token, 'platform': 'ANDROID'});
    } catch (_) {
      // hors ligne ou serveur plus ancien : sans conséquence, le jeton passera au prochain compte connecté
    }
    _token = null;
  }

  Future<void> _sendToServer(String token) async {
    try {
      await ApiClient().dio.post('/api/devices', data: {'token': token, 'platform': 'ANDROID'});
      _token = token;
    } catch (e) {
      debugPrint('Le serveur n\'a pas enregistré ce téléphone : $e');
    }
  }

  void _open(RemoteMessage message) {
    final type = message.data['type'];
    if (type is String && type.isNotEmpty) _navigate?.call(notificationDestination(type));
  }

  void _showInApp(RemoteMessage message) {
    final notification = message.notification;
    final messenger = _messengerKey?.currentState;
    if (notification == null || messenger == null) return;
    final text = [notification.title, notification.body].whereType<String>().where((t) => t.isNotEmpty).join('\n');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Voir', onPressed: () => _open(message)),
      ));
  }
}
