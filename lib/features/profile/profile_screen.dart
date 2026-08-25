import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildStats(),
              _buildInterests(),
              _buildSettings(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(height: 160, color: AppColors.surfaceLow),
        const Positioned(
          top: 16,
          right: 20,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 16),
              Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant, size: 22),
            ],
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                const CircleAvatar(
                  radius: 52,
                  backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/200?img=20'),
                  backgroundColor: AppColors.surfaceContainer,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Aziz, 25', style: AppTextStyles.headlineMd),
            Text('Tunis • Profil verifie ✅', style: AppTextStyles.bodyMdMuted),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('24', 'Matchs'),
          _buildStat('89%', 'Compat. moy.'),
          _buildStat('12', 'Evenements'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
        Text(label, style: AppTextStyles.labelSm),
      ],
    );
  }

  Widget _buildInterests() {
    final interests = ['Cinema', 'Musique Live', 'Gastronomie', 'Voyage', 'Art', 'Cafes'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes interets', style: AppTextStyles.labelMd),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: interests.map((i) => Chip(label: Text(i))).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final items = [
      {'icon': Icons.tune, 'title': 'Preferences de matching'},
      {'icon': Icons.notifications_outlined, 'title': 'Notifications'},
      {'icon': Icons.shield_outlined, 'title': 'Confidentialite'},
      {'icon': Icons.help_outline, 'title': 'Aide & Support'},
      {'icon': Icons.logout, 'title': 'Se deconnecter'},
    ];
    return Column(
      children: items.map((item) {
        final isLogout = item['title'] == 'Se deconnecter';
        return ListTile(
          leading: Icon(item['icon'] as IconData, color: isLogout ? AppColors.error : AppColors.onSurfaceVariant),
          title: Text(item['title'] as String, style: AppTextStyles.bodyMd.copyWith(color: isLogout ? AppColors.error : AppColors.onSurface)),
          trailing: isLogout ? null : const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: () {},
        );
      }).toList(),
    );
  }
}
