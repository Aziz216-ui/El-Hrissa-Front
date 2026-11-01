import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/message_models.dart';
import '../../core/models/people_models.dart';
import '../../core/models/swipe_models.dart';
import '../../core/services/message_service.dart';
import '../../core/services/people_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/couple_art.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/notification_bell.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/tab_band.dart';
import '../people/received_requests.dart';

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
  final _peopleService = PeopleService();
  List<_Conversation> _conversations = [];
  List<ConnectionRequest> _requests = [];
  final Set<int> _busyRequests = {};
  bool _isLoading = true;
  String? _error;
  String _query = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Nouvelles demandes et nouveaux messages sans recharger la page
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
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
      // Les demandes reçues : une erreur ici ne doit pas vider la liste des conversations
      List<ConnectionRequest> requests = [];
      try {
        requests = await _peopleService.getRequests();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _requests = requests;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _error = cleanError(e));
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPeople() async {
    await context.push('/search-people');
    if (mounted) _load();
  }

  Future<void> _acceptRequest(ConnectionRequest request) async {
    final profile = request.profile;
    if (_busyRequests.contains(profile.userId)) return;
    setState(() => _busyRequests.add(profile.userId));
    try {
      final result = await _peopleService.accept(profile.userId);
      if (!mounted) return;
      final matchId = result.matchId;
      if (matchId != null) {
        await context.push('/chat/detail', extra: {
          'matchId': matchId,
          'otherUserId': profile.userId,
          'userName': profile.displayName,
          'userPhotoUrl': profile.mainPhotoUrl,
        });
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busyRequests.remove(profile.userId));
    }
  }

  Future<void> _declineRequest(ConnectionRequest request) async {
    final profile = request.profile;
    if (_busyRequests.contains(profile.userId)) return;
    setState(() => _busyRequests.add(profile.userId));
    try {
      await _peopleService.decline(profile.userId);
      if (mounted) {
        setState(() => _requests = _requests.where((r) => r.profile.userId != profile.userId).toList());
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busyRequests.remove(profile.userId));
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
            // « El hadra » : la conversation
            TabBand(
              arabic: '\u0627\u0644\u0647\u062f\u0631\u0629',
              title: 'Messages',
              actions: [
                BandAction(icon: Icons.person_add_alt_1_outlined, tooltip: "Chercher quelqu'un", onPressed: _searchPeople),
                const NotificationBell(onBand: true),
              ],
            ),
            const SizedBox(height: 8),
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
    if (_conversations.isEmpty && _requests.isEmpty) {
      return EmptyView(
        icon: Icons.chat_bubble_outline_rounded,
        art: const CoupleArt(),
        title: 'Pas encore de match',
        subtitle: 'Likez des profils, ou cherchez quelqu\'un que vous connaissez : dès que c\'est mutuel, vous pourrez discuter ici.',
        actionLabel: 'Découvrir des profils',
        onAction: () => context.go('/swipe'),
      );
    }

    final children = <Widget>[
      if (_requests.isNotEmpty)
        ReceivedRequestsSection(
          requests: _requests,
          busy: _busyRequests,
          onAccept: _acceptRequest,
          onDecline: _declineRequest,
        ),
    ];
    if (_conversations.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('Acceptez une demande pour ouvrir votre première conversation.', style: AppTextStyles.bodyMdMuted),
      ));
    } else if (visible.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aucune conversation trouvée', style: AppTextStyles.bodyMdMuted)),
      ));
    } else {
      for (var i = 0; i < visible.length; i++) {
        if (i > 0) children.add(const Divider(height: 1, color: AppColors.outlineVariant));
        children.add(_buildItem(visible[i]));
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: children,
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
                    last?.content ?? 'Nouveau match. Dites bonjour !',
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
