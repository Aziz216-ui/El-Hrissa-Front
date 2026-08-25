import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeroBanner(),
                    const SizedBox(height: 24),
                    _buildCoupsDeCoeur(),
                    const SizedBox(height: 24),
                    _buildLieuxTendances(),
                    const SizedBox(height: 24),
                    _buildEvenements(),
                    const SizedBox(height: 24),
                    _buildVIPBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 0),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 4),
          Text('Tunis, TN', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic)),
          const Text(' 🌶️', style: TextStyle(fontSize: 20)),
          const Spacer(),
          Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.onSurface, size: 26),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFAF101A), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1539635278303-d4002c07eae3?w=800',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text("Aujourd'hui a Tunis", style: AppTextStyles.labelSm.copyWith(color: AppColors.white)),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Envie de bouger ?', style: AppTextStyles.headlineMd.copyWith(color: AppColors.white)),
                Text('245 evenements t\'attendent aujourd\'hui', style: AppTextStyles.labelSm.copyWith(color: AppColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupsDeCoeur() {
    final profiles = [
      {'name': 'Meriem', 'age': '23', 'compat': '95'},
      {'name': 'Yassine', 'age': '27', 'compat': '88'},
      {'name': 'Selma', 'age': '25', 'compat': '91'},
      {'name': 'Omar', 'age': '29', 'compat': '84'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('Coups de ', style: AppTextStyles.headlineMd),
            const Text('❤️', style: TextStyle(fontSize: 18)),
            const Spacer(),
            Text('Tout voir', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = profiles[index];
              return Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: CachedNetworkImageProvider(
                          'https://i.pravatar.cc/150?img=${index + 10}',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('%', style: AppTextStyles.labelSm.copyWith(color: AppColors.white, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p['name']!, style: AppTextStyles.labelSm),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLieuxTendances() {
    final lieux = [
      {
        'name': 'Le Rooftop du Lac',
        'desc': 'Un cadre idyllique pour un premier date. Vue imprenable sur les Berges...',
        'tags': ['Vue Lac', 'Cocktails', '\$\$'],
        'rating': '4.9',
        'badge': 'Partenaire Elahrisa -15%',
        'image': 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800',
      },
      {
        'name': 'Dar El-Behi',
        'desc': 'Une oasis de calme au coeur de Sidi Bou Said. Parfait pour une conversation...',
        'tags': ['Intime', 'Historique', '\$\$\$'],
        'rating': '4.7',
        'badge': 'Nouveau',
        'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Lieux Tendances', style: AppTextStyles.headlineMd),
            const Spacer(),
            const Icon(Icons.tune, color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        ...lieux.map((lieu) => _buildPlaceCard(lieu)),
      ],
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> lieu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: CachedNetworkImage(imageUrl: lieu['image'], height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌶️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(lieu['badge'], style: AppTextStyles.labelSm.copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_outline, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(lieu['name'], style: AppTextStyles.labelMd.copyWith(fontSize: 16))),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(lieu['rating'], style: AppTextStyles.labelMd),
                  ],
                ),
                const SizedBox(height: 4),
                Text(lieu['desc'], style: AppTextStyles.bodyMdMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: (lieu['tags'] as List<String>).map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvenements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evenements de la semaine', style: AppTextStyles.headlineMd),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎵', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Jazz Night at Gammarth', style: AppTextStyles.headlineMd.copyWith(color: AppColors.white)),
              const SizedBox(height: 4),
              Text('Samedi, 21h', style: AppTextStyles.labelSm.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text("S'inscrire", style: AppTextStyles.labelMd.copyWith(color: AppColors.secondary)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSmallEvent('🎨', 'Expos Art')),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallEvent('🍴', 'Foodie Tour')),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallEvent(String emoji, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.labelMd),
        ],
      ),
    );
  }

  Widget _buildVIPBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.onSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pack VIP', style: AppTextStyles.labelSm.copyWith(color: AppColors.pastelPinkDim)),
              Text('Date Night Premium', style: AppTextStyles.labelMd.copyWith(color: AppColors.white)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
