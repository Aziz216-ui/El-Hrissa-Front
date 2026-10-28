import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/message_models.dart';
import '../../core/models/swipe_models.dart';
import '../../core/services/message_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

class _Conversation {
  final MatchResponse match;
  final MessageResponse? lastMessage;
  _Conversation(this.match, this.lastMessage);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _swipeService = SwipeService();
  final _messageService = MessageService();
  List<_Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final matches = await _swipeService.getMyMatches();
      // Dernier message de chaque conversation (une erreur ponctuelle ne bloque pas la liste)
      final conversations = await Future.wait(matches.map((m) async {
        try {
          final msgs = await _messageService.getMessages(m.matchId, size: 1);
          return _Conversation(m, msgs.isNotEmpty ? msgs.first : null);
        } catch (_) {
          return _Conversation(m, null);
        }
      }));
      conversations.sort((a, b) {
        final ta = a.lastMessage?.createdAt ?? a.match.matchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.lastMessage?.createdAt ?? b.match.matchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      if (mounted) setState(() => _conversations = conversations);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _open(_Conversation c) async {
    await context.push('/chat/detail', extra: {
      'matchId': c.match.matchId,
      'otherUserId': c.match.profile.userId,
      'userName': c.match.profile.displayName,
      'userPhotoUrl': c.match.profile.mainPhotoUrl,
    });
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _conversations
        .where((c) => c.match.profile.displayName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

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
                decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une conversation...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
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
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBody(List<_Conversation> visible) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_conversations.isEmpty) {
      return EmptyView(
        emoji: '💬',
        title: 'Pas encore de match',
        subtitle: 'Likez des profils : dès que le sentiment est mutuel, vous pourrez discuter ici.',
        actionLabel: 'Découvrir des profils',
        onAction: () => context.go('/swipe'),
      );
    }
    if (visible.isEmpty) {
      return Center(child: Text('Aucune conversation trouvée', style: AppTextStyles.bodyMdMuted));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
        itemBuilder: (context, index) => _buildItem(visible[index]),
      ),
    );
  }

  Widget _buildItem(_Conversation c) {
    final profile = c.match.profile;
    final last = c.lastMessage;
    return InkWell(
      onTap: () => _open(c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            UserAvatar(url: profile.mainPhotoUrl, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayName, style: AppTextStyles.labelMd),
                  const SizedBox(height: 2),
                  Text(
                    last?.content ?? 'Nouveau match ! Dites bonjour 🌶️',
                    style: AppTextStyles.bodyMdMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(formatChatTime(last?.createdAt ?? c.match.matchedAt), style: AppTextStyles.labelSm),
          ],
        ),
      ),
    );
  }
}
