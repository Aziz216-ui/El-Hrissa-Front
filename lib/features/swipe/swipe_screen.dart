import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/profile_models.dart';
import '../../core/models/swipe_models.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/location_helper.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/notification_bell.dart';
import '../../shared/widgets/state_views.dart';

class SwipeScreen extends StatefulWidget {
  /// Si renseigné : on ne propose que les participants de cet événement.
  final int? eventId;
  const SwipeScreen({super.key, this.eventId});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _swipeService = SwipeService();
  final _profileService = ProfileService();

  List<CandidateResponse> _candidates = [];
  ProfileResponse? _myProfile;
  bool _isLoading = true;
  bool _isSwiping = false;
  String? _error;
  bool _needsLocation = false;
  int _currentIndex = 0;

  // Filtres
  double _radiusKm = 50;
  RangeValues _ageRange = const RangeValues(18, 60);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _needsLocation = false;
    });
    try {
      _myProfile = await _profileService.getMyProfile();
      if (widget.eventId == null && !_myProfile!.hasLocation) {
        // Première utilisation : on tente le GPS automatiquement
        final result = await LocationHelper.updateFromDevice();
        if (result != LocationResult.ok) {
          if (mounted) setState(() => _needsLocation = true);
          return;
        }
      }
      final candidates = await _swipeService.getCandidates(
        radiusKm: widget.eventId == null ? _radiusKm : null,
        ageMin: _ageRange.start.round(),
        ageMax: _ageRange.end.round(),
        eventId: widget.eventId,
      );
      if (mounted) {
        setState(() {
          _candidates = candidates;
          _currentIndex = 0;
        });
      }
    } catch (e) {
      final msg = cleanError(e);
      if (mounted) {
        setState(() {
          if (msg.toLowerCase().contains('position')) {
            _needsLocation = true;
          } else {
            _error = msg;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useGps() async {
    final result = await LocationHelper.updateFromDevice();
    if (!mounted) return;
    if (result == LocationResult.ok) {
      _load();
    } else {
      showSnack(context, LocationHelper.describe(result), error: true);
    }
  }

  Future<void> _useDefaultCity() async {
    try {
      await LocationHelper.useDefaultCity();
      if (mounted) _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Future<void> _onSwipe(bool liked) async {
    if (_isSwiping || _currentIndex >= _candidates.length) return;
    final candidate = _candidates[_currentIndex];
    setState(() {
      _isSwiping = true;
      _currentIndex++;
    });

    try {
      final res = await _swipeService.swipe(candidate.profile.userId, liked);
      if (res.matched && mounted) {
        _showMatchDialog(candidate.profile, res.matchId);
      }
    } catch (e) {
      // Le swipe n'a pas été enregistré : on remet la carte
      if (mounted) {
        setState(() => _currentIndex--);
        showSnack(context, cleanError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _isSwiping = false);
    }

    // Plus de cartes : on recharge pour voir s'il y a de nouveaux profils
    if (mounted && _currentIndex >= _candidates.length) {
      _load();
    }
  }

  void _showMatchDialog(PublicProfileResponse profile, int? matchId) {
    showDialog(
      context: context,
      builder: (dialogContext) => _MatchDialog(
        name: profile.displayName,
        photoUrl: profile.mainPhotoUrl,
        onMessage: matchId == null
            ? null
            : () {
                Navigator.pop(dialogContext);
                context.push('/chat/detail', extra: {
                  'matchId': matchId,
                  'otherUserId': profile.userId,
                  'userName': profile.displayName,
                  'userPhotoUrl': profile.mainPhotoUrl,
                });
              },
      ),
    );
  }

  Future<void> _openFilters() async {
    var radius = _radiusKm;
    var ages = _ageRange;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtres', style: AppTextStyles.headlineMd),
              const SizedBox(height: 20),
              Text('Distance maximale : ${radius.round()} km', style: AppTextStyles.labelMd),
              Slider(
                value: radius,
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: AppColors.primary,
                onChanged: (v) => setSheet(() => radius = v),
              ),
              const SizedBox(height: 8),
              Text('Âge : ${ages.start.round()} - ${ages.end.round()} ans', style: AppTextStyles.labelMd),
              RangeSlider(
                values: ages,
                min: 18,
                max: 80,
                divisions: 62,
                activeColor: AppColors.primary,
                onChanged: (v) => setSheet(() => ages = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Appliquer')),
            ],
          ),
        ),
      ),
    );
    if (apply == true) {
      _radiusKm = radius;
      _ageRange = ages;
      _load();
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
            if (_myProfile != null && !_myProfile!.complete) _buildIncompleteBanner(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: widget.eventId == null ? const ElBottomNav(currentIndex: 1) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_needsLocation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Activez votre position', style: AppTextStyles.headlineMd, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Nous avons besoin de votre position pour vous montrer des profils près de chez vous.',
                style: AppTextStyles.bodyMdMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _useGps,
                icon: const Icon(Icons.my_location),
                label: const Text('Utiliser ma position'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _useDefaultCity, child: const Text('Choisir Tunis par défaut')),
            ],
          ),
        ),
      );
    }
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_currentIndex >= _candidates.length) {
      return EmptyView(
        emoji: '🌶️',
        title: 'Plus de profils pour le moment',
        subtitle: 'Élargissez la distance ou la tranche d\'âge, ou revenez un peu plus tard.',
        actionLabel: 'Actualiser',
        onAction: _load,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v > 300) _onSwipe(true);
                if (v < -300) _onSwipe(false);
              },
              child: _buildCard(_candidates[_currentIndex]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIncompleteBanner() {
    return GestureDetector(
      onTap: () => context.push('/profile/edit'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ajoutez une photo et une bio pour apparaître dans les suggestions des autres.',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (widget.eventId != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            ),
          if (widget.eventId != null) const SizedBox(width: 12),
          GestureDetector(
            onTap: _openFilters,
            child: Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary, size: 20),
                const SizedBox(width: 4),
                Text('Filtres', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Spacer(),
          Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic)),
          const Text(' 🌶️', style: TextStyle(fontSize: 20)),
          const Spacer(),
          const NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildCard(CandidateResponse candidate) {
    final p = candidate.profile;
    final ageText = p.age != null ? ', ${p.age}' : '';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(url: p.mainPhotoUrl),
            Container(decoration: const BoxDecoration(gradient: AppColors.photoGradient)),
            if (candidate.distanceKm != null)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
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
                        Text(
                          candidate.distanceKm! < 1
                              ? 'À moins de 1 km'
                              : 'À ${candidate.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${p.displayName}$ageText',
                      style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.white)),
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                  if (p.interests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.interests.map((interest) {
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
        _ActionButton(
          onTap: () => _onSwipe(false),
          icon: Icons.close,
          color: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceWhite,
          size: 60,
        ),
        const SizedBox(width: 32),
        _ActionButton(
          onTap: () => _onSwipe(true),
          icon: Icons.favorite,
          color: AppColors.white,
          backgroundColor: AppColors.primary,
          size: 72,
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
    required this.onTap,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
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
  final String name;
  final String? photoUrl;
  final VoidCallback? onMessage;
  const _MatchDialog({required this.name, this.photoUrl, this.onMessage});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(url: photoUrl, radius: 44),
            const SizedBox(height: 12),
            Text("C'est un Match !", style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Vous et $name vous plaisez mutuellement !',
                style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (onMessage != null) ElevatedButton(onPressed: onMessage, child: const Text('Envoyer un message')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continuer')),
          ],
        ),
      ),
    );
  }
}
