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
import '../../shared/widgets/brand.dart';
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

  // Déplacement horizontal de la carte pendant le glissement
  double _dragDx = 0;
  bool _dragging = false;

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
        icon: Icons.explore_outlined,
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
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (d) => setState(() => _dragDx += d.delta.dx),
              onHorizontalDragCancel: _resetDrag,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                final liked = _dragDx > 100 || v > 500;
                final passed = _dragDx < -100 || v < -500;
                _resetDrag();
                if (liked) {
                  _onSwipe(true);
                } else if (passed) {
                  _onSwipe(false);
                }
              },
              child: AnimatedContainer(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transformAlignment: Alignment.bottomCenter,
                transform: Matrix4.translationValues(_dragDx, 0, 0)..rotateZ(_dragDx / 1400),
                child: _buildCard(_candidates[_currentIndex]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  void _resetDrag() {
    if (_dragDx == 0 && !_dragging) return;
    setState(() {
      _dragDx = 0;
      _dragging = false;
    });
  }

  Widget _buildIncompleteBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: AppColors.pastelPink,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () => context.push('/profile/edit'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
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
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          if (widget.eventId != null)
            IconButton(
              tooltip: 'Retour',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
            )
          else
            IconButton(
              tooltip: 'Filtres',
              onPressed: _openFilters,
              icon: const Icon(Icons.tune_rounded, color: AppColors.onSurface),
            ),
          const Spacer(),
          const Wordmark(),
          const Spacer(),
          if (widget.eventId != null)
            IconButton(
              tooltip: 'Filtres',
              onPressed: _openFilters,
              icon: const Icon(Icons.tune_rounded, color: AppColors.onSurface),
            ),
          const NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildCard(CandidateResponse candidate) {
    final p = candidate.profile;
    final ageText = p.age != null ? ', ${p.age}' : '';
    final stamp = (_dragDx.abs() / 110).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: archRadius(),
        boxShadow: [BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: archRadius(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(url: p.mainPhotoUrl),
            Container(decoration: const BoxDecoration(gradient: AppColors.photoGradient)),
            if (candidate.distanceKm != null)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_rounded, size: 16, color: AppColors.sidi),
                        const SizedBox(width: 4),
                        Text(
                          candidate.distanceKm! < 1
                              ? 'À moins de 1 km'
                              : 'À ${candidate.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.sidi),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_dragDx != 0)
              Positioned(
                top: 84,
                left: _dragDx > 0 ? 24 : null,
                right: _dragDx < 0 ? 24 : null,
                child: Opacity(
                  opacity: stamp,
                  child: _DecisionStamp(liked: _dragDx > 0),
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
          icon: Icons.close_rounded,
          label: 'Passer',
          color: AppColors.onSurfaceVariant,
          backgroundColor: AppColors.surfaceWhite,
          size: 60,
        ),
        const SizedBox(width: 36),
        _ActionButton(
          onTap: () => _onSwipe(true),
          icon: Icons.favorite_rounded,
          label: "J'aime",
          color: AppColors.white,
          backgroundColor: AppColors.primary,
          size: 72,
        ),
      ],
    );
  }
}

/// Bouton rond avec retour visuel (ripple), libellé pour les lecteurs d'écran et info-bulle.
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final double size;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(side: BorderSide(color: AppColors.outlineVariant)),
          elevation: 2,
          shadowColor: AppColors.onSurface.withValues(alpha: 0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: size * 0.45)),
          ),
        ),
      ),
    );
  }
}

/// Mention qui apparaît pendant le glissement : texte + icône, jamais la couleur seule.
class _DecisionStamp extends StatelessWidget {
  final bool liked;
  const _DecisionStamp({required this.liked});

  @override
  Widget build(BuildContext context) {
    final color = liked ? AppColors.white : AppColors.onSurface;
    return Transform.rotate(
      angle: liked ? -0.12 : 0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: liked ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(liked ? Icons.favorite_rounded : Icons.close_rounded, size: 20, color: color),
            const SizedBox(width: 6),
            Text(liked ? "J'aime" : 'Passer', style: AppTextStyles.titleMd.copyWith(color: color)),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: archRadius(top: 55, bottom: 16),
              child: SizedBox(width: 110, height: 128, child: NetworkPhoto(url: photoUrl, width: 110, height: 128)),
            ),
            const SizedBox(height: 16),
            Text("C'est un match", style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Vous et $name vous plaisez mutuellement.',
                style: AppTextStyles.bodyMdMuted, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (onMessage != null) ElevatedButton(onPressed: onMessage, child: Text('Écrire à $name')),
            const SizedBox(height: 4),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continuer à découvrir')),
          ],
        ),
      ),
    );
  }
}
