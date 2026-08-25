import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  final List<Map<String, dynamic>> _matches = const [
    {'name': 'Yasmine', 'last': 'Tu as aime le Jazz Night ?', 'time': '14h30', 'unread': 2, 'image': 'https://i.pravatar.cc/150?img=10'},
    {'name': 'Meriem', 'last': 'On se retrouve au Rooftop ?', 'time': '12h15', 'unread': 0, 'image': 'https://i.pravatar.cc/150?img=11'},
    {'name': 'Selma', 'last': '😊', 'time': 'Hier', 'unread': 1, 'image': 'https://i.pravatar.cc/150?img=12'},
    {'name': 'Nadia', 'last': 'Super de te rencontrer !', 'time': 'Lundi', 'unread': 0, 'image': 'https://i.pravatar.cc/150?img=13'},
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
              child: Text('Messages', style: AppTextStyles.headlineLgMobile),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une conversation...',
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _matches.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
                itemBuilder: (context, index) => _buildChatItem(_matches[index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 3),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> match) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: CachedNetworkImageProvider(match['image'])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match['name'], style: AppTextStyles.labelMd),
                const SizedBox(height: 2),
                Text(match['last'], style: AppTextStyles.bodyMdMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(match['time'], style: AppTextStyles.labelSm),
              if (match['unread'] > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Text('', style: AppTextStyles.labelSm.copyWith(color: AppColors.white, fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
