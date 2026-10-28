import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_state.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_detail_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/events/events_screen.dart';
import 'features/home/home_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/blocked_users_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/swipe/swipe_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.instance.init();
  runApp(const ElHrissaApp());
}

const _publicRoutes = {'/login', '/register'};

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  refreshListenable: AuthState.instance,
  redirect: (context, state) {
    final loggedIn = AuthState.instance.loggedIn ?? false;
    final path = state.matchedLocation;
    final isPublic = _publicRoutes.contains(path);

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && isPublic) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
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
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page introuvable', style: TextStyle(color: AppColors.onSurfaceVariant))),
  ),
);

class ElHrissaApp extends StatelessWidget {
  const ElHrissaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Elahrisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
