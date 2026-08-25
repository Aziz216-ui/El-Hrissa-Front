import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/swipe/swipe_screen.dart';
import 'features/events/events_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  runApp(const ElHrissaApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/swipe', builder: (context, state) => const SwipeScreen()),
    GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
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
