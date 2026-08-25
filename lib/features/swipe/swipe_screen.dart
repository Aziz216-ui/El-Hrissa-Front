import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Yasmine',
      'age': 24,
      'city': 'Tunis',
      'compat': 89,
      'interests': ['Cinema', 'Cafes branches', 'Musique Live'],
      'image': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
    },
    {
      'name': 'Meriem',
      'age': 23,
      'city': 'Carthage',
      'compat': 95,
      'interests': ['Art', 'Voyage', 'Gastronomie'],
      'image': 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800',
    },
    {
      'name': 'Nadia',
      'age': 26,
      'city': 'La Marsa',
      'compat': 82,
      'interests': ['Sport', 'Lecture', 'Meditation'],
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
    },
  ];

  int _currentIndex = 0;

  void _onSwipe(bool isLike) {
    setState(() {
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex++;
      }
    });
    if (isLike) {
      _showMatchDialog();
    }
  }

  void _showMatchDialog() {
    // Simule un match 30% du temps
    if (DateTime.now().millisecond % 3 == 0) {
      showDialog(
        context: context,
        builder: (_) => _MatchDialog(profile: _profiles[_currentIndex > 0 ? _currentIndex - 1 : 0]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildCardStack()),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 8),
            Text(
              'Elahrisa Match System™ : Base sur vos gouts culturels.',
              style: AppTextStyles.labelSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 4),
          Text('Tunis', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic)),
          const Text(' 🌶️', style: TextStyle(fontSize: 20)),
          const Spacer(),
          Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.onSurface, size: 26),
              Positioned(
                right: 0, top: 0,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_currentIndex >= _profiles.length) {
      return Center(child: Text('Plus de profils pour aujourd\'hui !', style: AppTextStyles.bodyLg));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) _onSwipe(true);
          if (details.primaryVelocity! < -300) _onSwipe(false);
        },
        child: _buildProfileCard(_profiles[_currentIndex]),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Photo plein ecran
            CachedNetworkImage(
              imageUrl: profile['image'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(decoration: const BoxDecoration(gradient: AppColors.photoGradient)),
            // Badge compatibilite
            Positioned(
              top: 16,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌶️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('ADN Compatibilite : %',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            // Info en bas
            Positioned(
              bottom: 24, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(', ',
                        style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.white)),
                      const SizedBox(width: 8),
                      Text(profile['city'], style: AppTextStyles.bodyMd.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile['interests'] as List<String>).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
                        ),
                        child: Text(interest, style: AppTextStyles.labelSm.copyWith(color: AppColors.white)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dislike
        _ActionButton(
          onTap: () => _onSwipe(false),
          icon: Icons.close,
          color: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceWhite,
          size: 52,
        ),
        const SizedBox(width: 20),
        // Super like
        _ActionButton(
          onTap: () {},
          icon: Icons.star_outline,
          color: Colors.blue,
          backgroundColor: AppColors.surfaceWhite,
          size: 44,
        ),
        const SizedBox(width: 20),
        // Like
        _ActionButton(
          onTap: () => _onSwipe(true),
          icon: Icons.favorite,
          color: AppColors.white,
          backgroundColor: AppColors.primary,
          size: 64,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;

  const _ActionButton({
    required this.onTap, required this.icon,
    required this.color, required this.backgroundColor, required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class _MatchDialog extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _MatchDialog({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text("C'est un Match !", style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Vous et  vous plaisez mutuellement !', style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Envoyer un message')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continuer')),
          ],
        ),
      ),
    );
  }
}
