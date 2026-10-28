import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/event_models.dart';
import '../../core/models/profile_models.dart';
import '../../core/models/swipe_models.dart';
import '../../core/services/event_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/notification_bell.dart';
import '../../shared/widgets/state_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileResponse? _profile;
  List<MatchResponse> _matches = [];
  List<EventResponse> _events = [];
  Set<int> _joined = {};
  bool _isLoading = true;
  String? _error;

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
      final results = await Future.wait([
        ProfileService().getMyProfile(),
        SwipeService().getMyMatches(),
        EventService().getEvents(size: 3),
        EventService().getJoinedEventIds(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as ProfileResponse;
          _matches = results[1] as List<MatchResponse>;
          _events = results[2] as List<EventResponse>;
          _joined = results[3] as Set<int>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(MatchResponse m) {
    context.push('/chat/detail', extra: {
      'matchId': m.matchId,
      'otherUserId': m.profile.userId,
      'userName': m.profile.displayName,
      'userPhotoUrl': m.profile.mainPhotoUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildHero(),
          if (!(_profile?.complete ?? true)) ...[
            const SizedBox(height: 16),
            _buildCompleteProfileCard(),
          ],
          const SizedBox(height: 24),
          _buildMatches(),
          const SizedBox(height: 24),
          _buildEvents(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic)),
          const Text(' 🌶️', style: TextStyle(fontSize: 20)),
          const Spacer(),
          const NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final name = (_profile?.displayName?.trim().isNotEmpty ?? false) ? _profile!.displayName! : null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.redGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name != null ? 'Bonjour $name 👋' : 'Bienvenue 👋', style: AppTextStyles.headlineMdWhite),
          const SizedBox(height: 6),
          Text(
            _matches.isEmpty
                ? 'Découvrez des profils près de chez vous.'
                : 'Vous avez ${_matches.length} match${_matches.length > 1 ? 's' : ''}. Continuez la conversation !',
            style: AppTextStyles.bodyMdWhite,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/swipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(180, 46),
            ),
            child: const Text('Découvrir des profils'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileCard() {
    return GestureDetector(
      onTap: () => context.push('/profile/edit').then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complétez votre profil', style: AppTextStyles.labelMd.copyWith(color: AppColors.primaryDark)),
                  const SizedBox(height: 2),
                  Text('Photo, bio et centres d\'intérêt : sans cela, les autres ne vous verront pas.',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Vos matchs', style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
            const Spacer(),
            if (_matches.isNotEmpty)
              GestureDetector(
                onTap: () => context.go('/chat'),
                child: Text('Voir tout', style: AppTextStyles.labelMdPrimary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_matches.isEmpty)
          Text('Pas encore de match. Likez des profils pour en créer !', style: AppTextStyles.bodyMdMuted)
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _matches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final m = _matches[i];
                return GestureDetector(
                  onTap: () => _openChat(m),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        UserAvatar(url: m.profile.mainPhotoUrl, radius: 30),
                        const SizedBox(height: 6),
                        Text(m.profile.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelSm),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Prochains événements', style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
            const Spacer(),
            if (_events.isNotEmpty)
              GestureDetector(
                onTap: () => context.go('/events'),
                child: Text('Voir tout', style: AppTextStyles.labelMdPrimary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_events.isEmpty)
          Text('Aucun événement prévu pour le moment.', style: AppTextStyles.bodyMdMuted)
        else
          ..._events.map(
            (e) => GestureDetector(
              onTap: () => context.go('/events'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.celebration, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: AppTextStyles.labelMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(formatEventDate(e.startsAt), style: AppTextStyles.labelSm),
                        ],
                      ),
                    ),
                    if (_joined.contains(e.id)) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
