import 'package:flutter/material.dart';
import '../../core/models/moderation_models.dart';
import '../../core/services/moderation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/state_views.dart';

/// Chiffres globaux de l'application, réservés aux modérateurs et organisateurs.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final _service = ModerationService();
  AppStats? _stats;
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
      final stats = await _service.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final s = _stats!;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Utilisateurs', [
            _Stat('Inscrits', s.totalUsers, Icons.people_outline),
            _Stat('Email vérifié', s.emailVerifiedUsers, Icons.mark_email_read_outlined),
            _Stat('Hommes', s.menCount, Icons.man_outlined),
            _Stat('Femmes', s.womenCount, Icons.woman_outlined),
            _Stat('Nouveaux profils (7 j)', s.newProfilesLast7Days, Icons.person_add_alt_outlined),
          ]),
          _section('Vérifications de profil', [
            _Stat('En attente', s.verificationPending, Icons.hourglass_top, highlight: s.verificationPending > 0),
            _Stat('Approuvées', s.verificationApproved, Icons.verified_outlined),
            _Stat('Refusées', s.verificationRejected, Icons.cancel_outlined),
            _Stat('Non envoyées', s.verificationNotSubmitted, Icons.person_outline),
          ]),
          _section('Activité', [
            _Stat('Matchs', s.totalMatches, Icons.favorite_border),
            _Stat('Matchs (7 j)', s.matchesLast7Days, Icons.favorite_border),
            _Stat('Messages', s.totalMessages, Icons.chat_bubble_outline),
            _Stat('Messages (7 j)', s.messagesLast7Days, Icons.chat_bubble_outline),
          ]),
          _section('Événements et signalements', [
            _Stat('Événements', s.totalEvents, Icons.event_outlined),
            _Stat('À venir', s.upcomingEvents, Icons.event_available_outlined),
            _Stat('Signalements en attente', s.reportsPending, Icons.flag_outlined, highlight: s.reportsPending > 0),
            _Stat('Signalements au total', s.reportsTotal, Icons.flag_outlined),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<_Stat> stats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMd),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats.map(_card).toList(),
          ),
        ],
      ),
    );
  }

  Widget _card(_Stat stat) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stat.highlight ? AppColors.pastelPink : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text('${stat.value}', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
          Text(stat.label, style: AppTextStyles.labelSm),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final bool highlight;
  const _Stat(this.label, this.value, this.icon, {this.highlight = false});
}
