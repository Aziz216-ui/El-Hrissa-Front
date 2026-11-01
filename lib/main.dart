import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_state.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/web_frame.dart';
import 'features/auth/complete_identity_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_detail_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/events/events_screen.dart';
import 'features/events/my_events_screen.dart';
import 'features/events/organizer_screen.dart';
import 'features/home/home_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/moderation/moderation_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/people/people_search_screen.dart';
import 'features/profile/blocked_users_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/swipe/swipe_screen.dart';
import 'features/welcome/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.instance.init();
  runApp(const ElHrissaApp());

  // Notifications push : après l'affichage de l'app, sans la retarder. Facultatif (Android seulement).
  AuthState.instance.addListener(_syncPushRegistration);
  await PushService.instance.init(navigate: _router.go, messengerKey: _messengerKey);
  _syncPushRegistration();
}

final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

bool _pushRegistered = false;

/// Dès qu'on est connecté, ce téléphone est enregistré pour recevoir les notifications.
void _syncPushRegistration() {
  final loggedIn = AuthState.instance.loggedIn == true && !AuthState.instance.needsIdentity;
  if (loggedIn && !_pushRegistered) {
    _pushRegistered = true;
    PushService.instance.register();
  } else if (!loggedIn) {
    _pushRegistered = false;
  }
}

// Lisibles par tous, connecté ou non
const _openRoutes = {'/terms', '/privacy'};

const _publicRoutes = {'/welcome', '/login', '/register', '/forgot-password'};

const _identityRoute = '/complete-identity';

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  refreshListenable: AuthState.instance,
  redirect: (context, state) {
    final loggedIn = AuthState.instance.loggedIn ?? false;
    final path = state.matchedLocation;
    if (_openRoutes.contains(path)) return null;
    final isPublic = _publicRoutes.contains(path);

    // Compte Google sans genre ni date de naissance : étape obligatoire avant l'app
    if (loggedIn && AuthState.instance.needsIdentity) return path == _identityRoute ? null : _identityRoute;
    if (path == _identityRoute) return loggedIn ? '/home' : '/welcome';

    if (!loggedIn && !isPublic) return '/welcome';
    if (loggedIn && isPublic) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/terms', builder: (context, state) => const LegalScreen.terms()),
    GoRoute(path: '/privacy', builder: (context, state) => const LegalScreen.privacy()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: _identityRoute, builder: (context, state) => const CompleteIdentityScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(initialEmail: state.extra is String ? state.extra as String : ''),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/swipe',
      builder: (context, state) =>
          SwipeScreen(key: ValueKey(state.uri.toString()), eventId: int.tryParse(state.uri.queryParameters['eventId'] ?? '')),
    ),
    GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
    GoRoute(
      path: '/chat/detail',
      redirect: (context, state) => state.extra is Map ? null : '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChatDetailScreen(
          matchId: extra['matchId'] as int,
          otherUserId: extra['otherUserId'] as int,
          userName: extra['userName'] as String,
          userPhotoUrl: extra['userPhotoUrl'] as String?,
        );
      },
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/blocked', builder: (context, state) => const BlockedUsersScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/search-people', builder: (context, state) => const PeopleSearchScreen()),
    GoRoute(path: '/moderation', builder: (context, state) => const ModerationScreen()),
    GoRoute(path: '/my-events', builder: (context, state) => const MyEventsScreen()),
    GoRoute(
      path: '/organizer/:id',
      builder: (context, state) => OrganizerScreen(userId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page introuvable', style: TextStyle(color: AppColors.onSurfaceVariant))),
  ),
);

/// Sur le site, on glisse aussi à la souris (cartes, listes) et pas seulement au doigt.
class _AnyDeviceScrollBehavior extends MaterialScrollBehavior {
  const _AnyDeviceScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class ElHrissaApp extends StatelessWidget {
  const ElHrissaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Elahrisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: _messengerKey,
      scrollBehavior: const _AnyDeviceScrollBehavior(),
      builder: (context, child) => WebFrame(child: child ?? const SizedBox.shrink()),
      routerConfig: _router,
    );
  }
}
