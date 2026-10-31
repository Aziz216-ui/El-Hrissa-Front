import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/auth_state.dart';
import '../../core/models/profile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/event_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/location_helper.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  ProfileResponse? _profile;
  int _matchCount = 0;
  int _eventCount = 0;
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
        _profileService.getMyProfile(),
        SwipeService().getMyMatches(),
        EventService().getJoinedEventIds(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as ProfileResponse;
          _matchCount = (results[1] as List).length;
          _eventCount = (results[2] as Set).length;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout(); // le routeur redirige vers /login
  }

  Future<void> _updateLocation() async {
    final result = await LocationHelper.updateFromDevice();
    if (!mounted) return;
    showSnack(context, LocationHelper.describe(result), error: result != LocationResult.ok);
    if (result == LocationResult.ok) _load();
  }

  Future<void> _verifyProfile() async {
    final status = _profile?.verificationStatus;
    if (status == 'APPROVED') {
      showSnack(context, 'Votre profil est déjà vérifié ✅');
      return;
    }
    if (status == 'PENDING') {
      showSnack(context, 'Votre selfie est en cours de vérification');
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vérifier mon profil'),
        content: const Text(
          'Prenez un selfie net, visage découvert. Il ne sera vu que par notre équipe de modération '
          'et sert à obtenir le badge « profil vérifié ».',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Prendre un selfie')),
        ],
      ),
    );
    if (go != true) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      await _profileService.submitVerification(file);
      if (mounted) {
        showSnack(context, 'Selfie envoyé. Vous serez notifié(e) après examen.');
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
      if (mounted) showSnack(context, 'Email de vérification envoyé');
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            title: const Text('Supprimer mon compte ?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cette action est définitive : votre profil, vos photos, vos matchs et vos messages '
                  'seront supprimés et ne pourront pas être récupérés.',
                ),
                const SizedBox(height: 16),
                const Text('Tapez SUPPRIMER pour confirmer :'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialog(() {}),
                  decoration: const InputDecoration(hintText: 'SUPPRIMER'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              TextButton(
                onPressed: controller.text.trim().toUpperCase() == 'SUPPRIMER' ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Supprimer définitivement', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;
    try {
      await _authService.deleteMyAccount(); // déconnecte puis le routeur renvoie vers /login
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Widget _buildEmailBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Votre email n'est pas vérifié. Ouvrez le lien reçu par email, puis actualisez cette page.",
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark),
            ),
          ),
          TextButton(onPressed: _resendVerificationEmail, child: const Text('Renvoyer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHeader(),
                          if (!_profile!.emailVerified) _buildEmailBanner(),
                          _buildStats(),
                          _buildInterests(),
                          _buildSettings(),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeader() {
    final p = _profile!;
    final title = [
      if (p.displayName != null && p.displayName!.isNotEmpty) p.displayName!,
      if (p.age != null) '${p.age}',
    ].join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      color: AppColors.surfaceLow,
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(url: p.mainPhotoUrl, radius: 52),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit').then((_) => _load()),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title.isEmpty ? 'Mon profil' : title, style: AppTextStyles.headlineMd),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (p.verificationStatus == 'APPROVED')
                Text('Profil vérifié ✅', style: AppTextStyles.bodyMdMuted)
              else if (p.verificationStatus == 'PENDING')
                Text('Vérification en cours ⏳', style: AppTextStyles.bodyMdMuted)
              else if (p.verificationStatus == 'REJECTED')
                Text('Vérification refusée', style: AppTextStyles.bodyMdMuted.copyWith(color: AppColors.error))
              else
                Text('Profil non vérifié', style: AppTextStyles.bodyMdMuted),
            ],
          ),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.bio!, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('$_matchCount', 'Matchs'),
          _buildStat('$_eventCount', 'Événements'),
          _buildStat('${_profile!.photos.length}', 'Photos'),
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
    final interests = _profile!.interests;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes intérêts', style: AppTextStyles.labelMd),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text('Aucun centre d\'intérêt renseigné.', style: AppTextStyles.bodyMdMuted)
          else
            Wrap(spacing: 8, runSpacing: 8, children: interests.map((i) => Chip(label: Text(i))).toList()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final items = <_SettingItem>[
      _SettingItem(Icons.edit_outlined, 'Modifier mon profil et mes photos',
          () => context.push('/profile/edit').then((_) => _load())),
      _SettingItem(Icons.my_location, 'Mettre à jour ma position', _updateLocation),
      _SettingItem(Icons.verified_outlined, 'Vérifier mon profil', _verifyProfile),
      _SettingItem(Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
      _SettingItem(Icons.block, 'Utilisateurs bloqués', () => context.push('/blocked')),
      if (AuthState.instance.isOrganizer)
        _SettingItem(Icons.admin_panel_settings_outlined, 'Modération', () => context.push('/moderation')),
      _SettingItem(Icons.mark_email_read_outlined, "Renvoyer l'email de vérification", _resendVerificationEmail),
      _SettingItem(Icons.description_outlined, "Conditions d'utilisation", () => context.push('/terms')),
      _SettingItem(Icons.privacy_tip_outlined, 'Politique de confidentialité', () => context.push('/privacy')),
      _SettingItem(Icons.logout, 'Se déconnecter', _logout, destructive: true),
      _SettingItem(Icons.delete_forever_outlined, 'Supprimer mon compte', _deleteAccount, destructive: true),
    ];
    return Column(
      children: items
          .map((item) => ListTile(
                leading: Icon(item.icon, color: item.destructive ? AppColors.error : AppColors.onSurfaceVariant),
                title: Text(item.title,
                    style: AppTextStyles.bodyMd.copyWith(color: item.destructive ? AppColors.error : AppColors.onSurface)),
                trailing: item.destructive ? null : const Icon(Icons.chevron_right, color: AppColors.outline),
                onTap: item.onTap,
              ))
          .toList(),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  _SettingItem(this.icon, this.title, this.onTap, {this.destructive = false});
}
