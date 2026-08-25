import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  final List<Map<String, dynamic>> _events = const [
    {'title': 'Jazz Night at Gammarth', 'date': 'Samedi, 21h', 'category': 'Musique', 'emoji': '🎵', 'color': 0xFFAC3509, 'image': 'https://images.unsplash.com/photo-1501386761578-eaa54b90f93e?w=800'},
    {'title': 'Expos Art Contemporain', 'date': 'Dimanche, 10h', 'category': 'Art', 'emoji': '🎨', 'color': 0xFF625457, 'image': 'https://images.unsplash.com/photo-1518998053901-5348d3961a04?w=800'},
    {'title': 'Foodie Tour Medina', 'date': 'Vendredi, 18h', 'category': 'Gastronomie', 'emoji': '🍴', 'color': 0xFF8B4513, 'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800'},
    {'title': 'Soiree Cinema en Plein Air', 'date': 'Jeudi, 21h', 'category': 'Cinema', 'emoji': '🎬', 'color': 0xFF1A237E, 'image': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Evenements', style: AppTextStyles.headlineLgMobile),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Filtrer', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _events.length,
                itemBuilder: (context, index) => _buildEventCard(_events[index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CachedNetworkImage(imageUrl: event['image'], height: 180, width: double.infinity, fit: BoxFit.cover,
              color: Color(event['color'] as int).withValues(alpha: 0.5), colorBlendMode: BlendMode.multiply),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.surfaceWhite.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event['emoji'], style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(event['category'], style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'], style: AppTextStyles.labelMd.copyWith(color: AppColors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(event['date'], style: AppTextStyles.labelSm.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: Text("S'inscrire", style: AppTextStyles.labelSm.copyWith(color: AppColors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
