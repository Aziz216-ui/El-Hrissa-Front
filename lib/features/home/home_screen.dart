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
import '../../shared/widgets/brand.dart';
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 8, 4),
      child: Row(
        children: [
          Wordmark(),
          Spacer(),
          NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final name = (_profile?.displayName?.trim().isNotEmpty ?? false) ? _profile!.displayName! : null;
    final subtitle = _matches.isEmpty
        ? 'Découvrez des profils près de chez vous.'
        : 'Vous avez ${_matches.length} match${_matches.length > 1 ? 's' : ''}. Continuez la conversation.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name != null ? 'Bonjour $name' : 'Bienvenue', style: AppTextStyles.headlineLg),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.bodyMdMuted),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () => context.go('/swipe'),
          icon: const Icon(Icons.style_rounded),
          label: const Text('Découvrir des profils'),
        ),
      ],
    );
  }

  Widget _buildCompleteProfileCard() {
    return Material(
      color: AppColors.pastelPink,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => context.push('/profile/edit').then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 28),
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMd),
        const Spacer(),
        if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
      ],
    );
  }

  Widget _buildMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Vos matchs', onSeeAll: _matches.isEmpty ? null : () => context.go('/chat')),
        const SizedBox(height: 8),
        if (_matches.isEmpty)
          Text('Pas encore de match. Likez des profils pour en créer.', style: AppTextStyles.bodyMdMuted)
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _matches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = _matches[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  onTap: () => _openChat(m),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
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
        _sectionHeader('Prochains événements', onSeeAll: _events.isEmpty ? null : () => context.go('/events')),
        const SizedBox(height: 8),
        if (_events.isEmpty)
          Text('Aucun événement prévu pour le moment.', style: AppTextStyles.bodyMdMuted)
        else
          ..._events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surfaceWhite,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => context.go('/events'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ExcludeSemantics(child: EventDateStub(date: e.startsAt, size: 48)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: AppTextStyles.labelMd.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(formatEventDate(e.startsAt), style: AppTextStyles.labelSm),
                            ],
                          ),
                        ),
                        if (_joined.contains(e.id))
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle_rounded, color: AppColors.sidi, size: 22, semanticLabel: 'Inscrit'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
