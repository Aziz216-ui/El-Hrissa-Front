import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/event_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';
import 'event_form_sheet.dart';
import 'events_screen.dart' show eventPlaceText;

/// Espace organisateur : mes sorties, qui s'est inscrit, qui attend, et de quoi les modifier.
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _service = EventService();
  List<EventResponse> _events = [];
  bool _loading = true;
  String? _error;
  int? _myId;

  @override
  void initState() {
    super.initState();
    AuthService().getCurrentUserId().then((id) => _myId = id);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _service.getMyEvents();
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([EventResponse? event]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EventFormSheet(initial: event),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(EventResponse event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'événement ?"),
        content: Text('« ${event.name} » sera supprimé pour ses ${event.attendeeCount} participants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteEvent(event.id);
      if (mounted) _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  void _showAttendees(EventResponse event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AttendeesSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Mes événements', style: AppTextStyles.headlineMd)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Créer'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_events.isEmpty) {
      return EmptyView(
        icon: Icons.event_note_outlined,
        title: 'Aucune sortie pour le moment',
        subtitle: 'Créez votre première sortie : les gens s\'y inscrivent et peuvent se rencontrer entre eux.',
        actionLabel: 'Créer une sortie',
        onAction: () => _openForm(),
      );
    }
    final upcoming = _events.where((e) => !e.hasEnded).toList().reversed.toList();
    final past = _events.where((e) => e.hasEnded).toList();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          if (_myId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/organizer/$_myId'),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('Voir ma page publique'),
              ),
            ),
          if (upcoming.isNotEmpty) ...[
            const _SectionTitle('À venir'),
            for (final e in upcoming) _card(e),
          ],
          if (past.isNotEmpty) ...[
            const _SectionTitle('Terminés'),
            for (final e in past) _card(e),
          ],
        ],
      ),
    );
  }

  Widget _card(EventResponse event) {
    final place = eventPlaceText(event);
    final capacity = event.capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: EventDateStub(date: event.startsAt)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name, style: AppTextStyles.titleMd, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(formatEventDate(event.startsAt), style: AppTextStyles.labelSm),
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(place, style: AppTextStyles.labelMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Stat(
                    icon: Icons.group_outlined,
                    text: capacity == null ? '${event.attendeeCount} inscrits' : '${event.attendeeCount}/$capacity places',
                  ),
                  if ((event.waitlistCount ?? 0) > 0)
                    _Stat(icon: Icons.hourglass_bottom_rounded, text: '${event.waitlistCount} en attente', warn: true),
                  if (event.isFull && !event.hasEnded) const _Stat(icon: Icons.block_rounded, text: 'Complet', warn: true),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: event.attendeeCount == 0 ? null : () => _showAttendees(event),
                    icon: const Icon(Icons.people_outline, size: 18),
                    label: const Text('Inscrits'),
                  ),
                  TextButton.icon(
                    onPressed: () => _openForm(event),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                  ),
                  TextButton.icon(
                    onPressed: () => _delete(event),
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    label: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
        child: Text(text, style: AppTextStyles.titleMd.copyWith(fontSize: 18)),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warn;
  const _Stat({required this.icon, required this.text, this.warn = false});

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppColors.primary : AppColors.sidi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: warn ? AppColors.pastelPink : AppColors.sidiTint, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Les inscrits d'une sortie : prénom, âge et photo (leur profil public).
class _AttendeesSheet extends StatefulWidget {
  final EventResponse event;
  const _AttendeesSheet({required this.event});

  @override
  State<_AttendeesSheet> createState() => _AttendeesSheetState();
}

class _AttendeesSheetState extends State<_AttendeesSheet> {
  List<dynamic>? _people;
  String? _error;

  @override
  void initState() {
    super.initState();
    EventService().getAttendees(widget.event.id).then((p) {
      if (mounted) setState(() => _people = p);
    }).catchError((e) {
      if (mounted) setState(() => _error = cleanError(e));
    });
  }

  @override
  Widget build(BuildContext context) {
    final people = _people;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          children: [
            Text('Inscrits (${widget.event.attendeeCount})', style: AppTextStyles.headlineMd),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))
            else if (people == null)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (people.isEmpty)
              Text('Personne pour le moment.', style: AppTextStyles.bodyMdMuted)
            else
              for (final p in people)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(url: p.mainPhotoUrl, radius: 22),
                  title: Text(p.age == null ? p.displayName : '${p.displayName}, ${p.age}'),
                ),
          ],
        ),
      ),
    );
  }
}
