import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class ElBottomNav extends StatelessWidget {
  final int currentIndex;
  const ElBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, index: 0, currentIndex: currentIndex, route: '/home'),
              _NavItem(icon: Icons.style_outlined, activeIcon: Icons.style, index: 1, currentIndex: currentIndex, route: '/swipe'),
              _NavItem(icon: Icons.celebration_outlined, activeIcon: Icons.celebration, index: 2, currentIndex: currentIndex, route: '/events'),
              _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, index: 3, currentIndex: currentIndex, route: '/chat'),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, index: 4, currentIndex: currentIndex, route: '/profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pastelPink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.outline,
          size: 24,
        ),
      ),
    );
  }
}
