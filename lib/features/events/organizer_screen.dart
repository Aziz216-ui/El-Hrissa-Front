import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/event_models.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/state_views.dart';
import 'events_screen.dart' show eventPlaceText;

/// Page publique d'un organisateur : qui il est, ce qu'il organise, combien de personnes le suivent.
class OrganizerScreen extends StatefulWidget {
  final int userId;
  const OrganizerScreen({super.key, required this.userId});

  @override
  State<OrganizerScreen> createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends State<OrganizerScreen> {
  OrganizerResponse? _organizer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final organizer = await EventService().getOrganizer(widget.userId);
      if (mounted) setState(() => _organizer = organizer);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Organisateur', style: AppTextStyles.headlineMd)),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    final o = _organizer;
    if (_error != null || o == null) return ErrorView(message: _error ?? 'Page introuvable', onRetry: _load);
    final initial = o.displayName.isEmpty ? '?' : o.displayName.characters.first.toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(initial, style: AppTextStyles.headlineMd.copyWith(color: AppColors.white)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.displayName, style: AppTextStyles.headlineMd),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: AppColors.sidi),
                      const SizedBox(width: 4),
                      Text('Organisateur vérifié', style: AppTextStyles.labelMd.copyWith(color: AppColors.sidi)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _Figure(value: '${o.eventsCount}', label: o.eventsCount > 1 ? 'sorties organisées' : 'sortie organisée')),
            const SizedBox(width: 12),
            Expanded(child: _Figure(value: '${o.participantsCount}', label: 'participations')),
          ],
        ),
        const SizedBox(height: 24),
        Text('À venir', style: AppTextStyles.titleMd.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        if (o.upcomingEvents.isEmpty)
          Text('Rien de prévu pour le moment.', style: AppTextStyles.bodyMdMuted)
        else
          for (final e in o.upcomingEvents) _eventTile(e),
      ],
    );
  }

  Widget _eventTile(EventResponse e) {
    final place = eventPlaceText(e);
    final spots = e.capacity == null ? null : (e.isFull ? 'Complet' : '${e.spotsLeft} places restantes');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Les événements s'ouvrent dans l'onglet Événements, où l'on s'inscrit
          onTap: () => context.go('/events'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ExcludeSemantics(child: EventDateStub(date: e.startsAt)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: AppTextStyles.titleMd, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(formatEventDate(e.startsAt), style: AppTextStyles.labelSm),
                      if (place.isNotEmpty) Text(place, style: AppTextStyles.labelMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (spots != null)
                        Text(spots, style: AppTextStyles.labelSm.copyWith(color: e.isFull ? AppColors.primary : AppColors.sidi)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;
  const _Figure({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sidiTint, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.sidi)),
          Text(label, style: AppTextStyles.labelMd),
        ],
      ),
    );
  }
}
