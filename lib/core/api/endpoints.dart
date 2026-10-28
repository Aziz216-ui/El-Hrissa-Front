import 'package:flutter/foundation.dart';

class Endpoints {
  /// URL de l'API, surchargeable au build :
  ///   flutter run --dart-define=API_BASE_URL=https://mon-api.example.com
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://localhost:8086';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8086'; // hôte vu depuis l'émulateur Android
    }
    return 'http://localhost:8086'; // simulateur iOS / desktop
  }

  /// Les photos sont renvoyées en chemin relatif (/uploads/...) : on les rend absolues.
  static String resolveUrl(String url) {
    if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String forgotPassword = '/api/auth/forgot-password';
  static String user(int id) => '/api/users/$id';

  // Profils
  static const String myProfile = '/api/profiles/me';
  static const String myPhotos = '/api/profiles/me/photos';
  static const String myLocation = '/api/profiles/me/location';
  static const String myVerification = '/api/profiles/me/verification';
  static String photo(int id) => '/api/profiles/me/photos/$id';
  static String mainPhoto(int id) => '/api/profiles/me/photos/$id/main';
  static String publicProfile(int userId) => '/api/profiles/$userId';

  // Swipes & matchs
  static const String candidates = '/api/swipes/candidates';
  static const String swipe = '/api/swipes';
  static const String myMatches = '/api/matches';
  static String unmatch(int matchId) => '/api/matches/$matchId';

  // Messages
  static String matchMessages(int matchId) => '/api/matches/$matchId/messages';

  // Événements
  static const String events = '/api/events';
  static const String joinedEvents = '/api/events/joined';
  static String eventDetails(int id) => '/api/events/$id';
  static String joinEvent(int id) => '/api/events/$id/join';
  static String leaveEvent(int id) => '/api/events/$id/join';
  static String eventAttendees(int id) => '/api/events/$id/attendees';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String unreadCount = '/api/notifications/unread-count';
  static const String readAllNotifications = '/api/notifications/read-all';
  static String readNotification(int id) => '/api/notifications/$id/read';

  // Sécurité
  static const String blocks = '/api/blocks';
  static String unblock(int userId) => '/api/blocks/$userId';
  static const String reports = '/api/reports';
}
