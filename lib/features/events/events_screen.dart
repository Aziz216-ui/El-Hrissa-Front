import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/models/event_models.dart';
import '../../core/models/profile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/event_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/utils/link_opener.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/notification_bell.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/tab_band.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _service = EventService();
  List<EventResponse> _events = [];
  Set<int> _joined = {};
  EventFilters _filters = const EventFilters();
  String? _city;
  String? _category;
  bool _isLoading = true;
  String? _error;
  final Set<int> _busy = {};
  int? _myId;

  bool get _hasActiveFilter => _city != null || _category != null;

  @override
  void initState() {
    super.initState();
    AuthService().getCurrentUserId().then((id) => _myId = id);
    _loadFilters();
    _load();
  }

  Future<void> _loadFilters() async {
    final filters = await _service.getFilters();
    if (mounted) setState(() => _filters = filters);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getEvents(city: _city, category: _category),
        _service.getJoinedEventIds(),
      ]);
      if (mounted) {
        setState(() {
          _events = results[0] as List<EventResponse>;
          _joined = results[1] as Set<int>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _city = null;
      _category = null;
    });
    _load();
  }

  /// Feuille de choix à une seule valeur ; renvoie '' pour « Tous » et null si on ferme sans choisir.
  Future<String?> _pick({
    required String title,
    required String allLabel,
    required List<MapEntry<String, String>> options,
    String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(title, style: AppTextStyles.titleMd),
              ),
              ListTile(
                title: Text(allLabel),
                trailing: selected == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.value),
                  trailing: selected == option.key ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(ctx, option.key),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final options = _filters.categories.map((c) => MapEntry(c, eventCategoryLabel(c))).toList();
    final result = await _pick(title: "Type d'événement", allLabel: 'Tous les types', options: options, selected: _category);
    if (result == null) return;
    setState(() => _category = result.isEmpty ? null : result);
    _load();
  }

  Future<void> _pickCity() async {
    final options = _filters.cities.map((c) => MapEntry(c, c)).toList();
    final result = await _pick(title: 'Lieu', allLabel: 'Tous les lieux', options: options, selected: _city);
    if (result == null) return;
    setState(() => _city = result.isEmpty ? null : result);
    _load();
  }

  Future<void> _toggle(EventResponse event) async {
    if (_busy.contains(event.id)) return;
    final wasJoined = _joined.contains(event.id);
    setState(() => _busy.add(event.id));
    try {
      if (wasJoined) {
        await _service.leaveEvent(event.id);
      } else {
        await _service.joinEvent(event.id);
      }
      if (!mounted) return;
      if (wasJoined) {
        showSnack(context, 'Inscription annulée');
      } else {
        // On ne laisse pas l'utilisateur devant un écran inchangé : on propose la suite
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Vous participez à « ${event.name} »'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.onSurface,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Rencontrer',
              textColor: AppColors.saffron,
              onPressed: () => _discover(event),
            ),
          ));
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(event.id));
    }
  }

  void _discover(EventResponse event) => context.push('/swipe?eventId=${event.id}');

  Future<void> _book(EventResponse event) async {
    final opened = await openExternalLink(event.sourceUrl ?? '');
    if (!opened && mounted) showSnack(context, 'Impossible d\'ouvrir la page de réservation', error: true);
  }

  Future<void> _createEvent() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateEventSheet(),
    );
    if (created == true) {
      _loadFilters();
      _load();
    }
  }

  Future<void> _deleteEvent(EventResponse event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement ?'),
        content: Text('« ${event.name} » sera supprimé pour tous les participants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteEvent(event.id);
      if (mounted) {
        Navigator.of(context).maybePop();
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  void _openDetail(EventResponse event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventDetailSheet(
        event: event,
        joined: _joined.contains(event.id),
        // Un organisateur ne supprime que ses propres événements
        canDelete: AuthState.instance.isOrganizer && event.createdByUserId != null && event.createdByUserId == _myId,
        onToggle: () {
          Navigator.pop(context);
          _toggle(event);
        },
        onDelete: () => _deleteEvent(event),
        onDiscover: () {
          Navigator.pop(context);
          _discover(event);
        },
        onBook: () => _book(event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AuthState.instance.isOrganizer
          ? FloatingActionButton.extended(
              onPressed: _createEvent,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer'),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // « Khrejet » : les sorties
            const TabBand(
              arabic: '\u062e\u0631\u062c\u0627\u062a',
              title: 'Événements',
              actions: [NotificationBell(onBand: true)],
            ),
            const SizedBox(height: 12),
            _buildFilterBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 2),
    );
  }

  Widget _buildFilterBar() {
    final showCategory = _filters.categories.isNotEmpty || _category != null;
    final showCity = _filters.cities.isNotEmpty || _city != null;
    if (!showCategory && !showCity) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showCategory)
            _FilterPill(
              icon: Icons.category_outlined,
              label: _category == null ? 'Type' : eventCategoryLabel(_category!),
              active: _category != null,
              onTap: _pickCategory,
            ),
          if (showCity)
            _FilterPill(
              icon: Icons.place_outlined,
              label: _city ?? 'Lieu',
              active: _city != null,
              onTap: _pickCity,
            ),
          if (_hasActiveFilter) TextButton(onPressed: _clearFilters, child: const Text('Effacer')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_events.isEmpty) {
      return _hasActiveFilter
          ? EmptyView(
              icon: Icons.filter_alt_off_outlined,
              title: 'Aucun événement pour ces filtres',
              subtitle: 'Essayez un autre type ou un autre lieu.',
              actionLabel: 'Effacer les filtres',
              onAction: _clearFilters,
            )
          : const EmptyView(
              icon: Icons.event_available_outlined,
              title: 'Aucun événement à venir',
              subtitle: 'Les prochaines sorties organisées apparaîtront ici.',
            );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: _events.length,
        itemBuilder: (context, index) => _buildCard(_events[index]),
      ),
    );
  }

  Widget _buildCard(EventResponse event) {
    final joined = _joined.contains(event.id);
    final busy = _busy.contains(event.id);
    final place = eventPlaceText(event);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(event),
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 16, color: AppColors.sidi),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (event.action != EventAction.suggestion) ...[
                      const SizedBox(width: 8),
                      Semantics(
                        label: '${event.attendeeCount} participants',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            const Icon(Icons.group_outlined, size: 18, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Text('${event.attendeeCount}', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                _EventTags(event: event),
                const SizedBox(height: 14),
                _buildAction(event, joined: joined, busy: busy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Une seule action claire par événement : réserver, s'inscrire, ou rien (simple suggestion).
  Widget _buildAction(EventResponse event, {required bool joined, required bool busy}) {
    switch (event.action) {
      case EventAction.book:
        return ElevatedButton.icon(
          onPressed: () => _book(event),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Réserver'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        );
      case EventAction.register:
        if (joined) {
          return Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _discover(event),
                icon: const Icon(Icons.style_rounded, size: 18),
                label: const Text('Rencontrer les participants'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: busy ? null : () => _toggle(event),
                child: const Text('Annuler mon inscription'),
              ),
            ],
          );
        }
        return ElevatedButton(
          onPressed: busy ? null : () => _toggle(event),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("S'inscrire"),
        );
      case EventAction.suggestion:
        return const _SuggestionNote();
    }
  }
}

/// « Théâtre El Teatro, Tunis » : le lieu et la ville, sans répéter la ville si elle est déjà dans le lieu.
String eventPlaceText(EventResponse event) {
  final venue = (event.venueName ?? '').trim();
  final city = (event.city ?? '').trim();
  if (venue.isEmpty) return city;
  if (city.isEmpty || venue.toLowerCase().contains(city.toLowerCase())) return venue;
  return '$venue, $city';
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.pastelPink : AppColors.surfaceWhite,
      shape: StadiumBorder(side: BorderSide(color: active ? AppColors.primary : AppColors.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(color: active ? AppColors.primary : AppColors.onSurface),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: active ? AppColors.primary : AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Type d'événement et prix, quand on les connaît.
class _EventTags extends StatelessWidget {
  final EventResponse event;
  const _EventTags({required this.event});

  @override
  Widget build(BuildContext context) {
    final price = (event.priceText ?? '').trim();
    if (event.category == null && price.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (event.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.sidiTint, borderRadius: BorderRadius.circular(20)),
              child: Text(
                eventCategoryLabel(event.category!),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.sidi, fontWeight: FontWeight.w600),
              ),
            ),
          if (price.isNotEmpty) Text(price, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Événement sans réservation ni inscription : une idée de sortie, présentée comme telle.
class _SuggestionNote extends StatelessWidget {
  const _SuggestionNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.sidiTint, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.sidi),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Suggestion de sortie : pas de réservation en ligne.',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.sidi, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailSheet extends StatefulWidget {
  final EventResponse event;
  final bool joined;
  final bool canDelete;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onDiscover;
  final VoidCallback onBook;

  const _EventDetailSheet({
    required this.event,
    required this.joined,
    required this.canDelete,
    required this.onToggle,
    required this.onDelete,
    required this.onDiscover,
    required this.onBook,
  });

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  List<PublicProfileResponse>? _attendees;

  @override
  void initState() {
    super.initState();
    if (widget.event.action == EventAction.suggestion) {
      _attendees = const [];
      return;
    }
    EventService().getAttendees(widget.event.id).then((a) {
      if (mounted) setState(() => _attendees = a);
    }).catchError((_) {
      if (mounted) setState(() => _attendees = []);
    });
  }

  void _openAttendee(PublicProfileResponse person) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceWhite,
      builder: (_) => _AttendeeSheet(person: person, eventName: widget.event.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final place = eventPlaceText(e);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: EventDateStub(date: e.startsAt, size: 64)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: AppTextStyles.headlineMd),
                    const SizedBox(height: 6),
                    Text(formatEventDate(e.startsAt), style: AppTextStyles.bodyMdMuted),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 18, color: AppColors.sidi),
                        const SizedBox(width: 4),
                        Expanded(child: Text(place, style: AppTextStyles.bodyMd)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          _EventTags(event: e),
          if (e.description != null && e.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(e.description!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
          if (e.action != EventAction.suggestion) ...[
            const SizedBox(height: 24),
            Text('Participants (${e.attendeeCount})', style: AppTextStyles.titleMd.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            if (_attendees == null)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_attendees!.isEmpty)
              Text(
                e.action == EventAction.book ? 'Personne ne s\'est encore signalé. Soyez le premier !' : 'Soyez le premier à vous inscrire !',
                style: AppTextStyles.bodyMdMuted,
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _attendees!
                    .map((a) => Semantics(
                          button: true,
                          label: 'Voir le profil de ${a.displayName}',
                          excludeSemantics: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openAttendee(a),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Column(children: [
                                UserAvatar(url: a.mainPhotoUrl, radius: 26),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 64,
                                  child: Text(a.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelSm),
                                ),
                              ]),
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
          const SizedBox(height: 24),
          ..._actions(e),
          if (widget.canDelete) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onDelete,
              child: const Text('Supprimer l\'événement', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _actions(EventResponse e) {
    switch (e.action) {
      case EventAction.book:
        return [
          ElevatedButton.icon(
            onPressed: widget.onBook,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Réserver'),
          ),
          const SizedBox(height: 10),
          if (widget.joined) ...[
            ElevatedButton.icon(
              onPressed: widget.onDiscover,
              icon: const Icon(Icons.style_rounded),
              label: const Text('Rencontrer les participants'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sidiTint, foregroundColor: AppColors.sidi, elevation: 0),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: widget.onToggle,
            child: Text(widget.joined ? "Je n'y vais plus" : 'Je compte y aller'),
          ),
        ];
      case EventAction.register:
        return [
          if (widget.joined) ...[
            ElevatedButton.icon(
              onPressed: widget.onDiscover,
              icon: const Icon(Icons.style_rounded),
              label: const Text('Rencontrer les participants'),
            ),
            const SizedBox(height: 10),
          ],
          widget.joined
              ? OutlinedButton(onPressed: widget.onToggle, child: const Text('Annuler mon inscription'))
              : ElevatedButton(onPressed: widget.onToggle, child: const Text("S'inscrire")),
        ];
      case EventAction.suggestion:
        return const [_SuggestionNote()];
    }
  }
}

/// Une personne qui va au même événement : sa photo, sa bio, et un bouton pour lui dire qu'on aimerait la connaître.
class _AttendeeSheet extends StatefulWidget {
  final PublicProfileResponse person;
  final String eventName;
  const _AttendeeSheet({required this.person, required this.eventName});

  @override
  State<_AttendeeSheet> createState() => _AttendeeSheetState();
}

class _AttendeeSheetState extends State<_AttendeeSheet> {
  bool _busy = false;
  bool _sent = false;
  int? _matchId;

  Future<void> _like() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await SwipeService().swipe(widget.person.userId, true);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _matchId = result.matched ? result.matchId : null;
      });
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openChat() {
    final p = widget.person;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/chat/detail', extra: {
      'matchId': _matchId,
      'otherUserId': p.userId,
      'userName': p.displayName,
      'userPhotoUrl': p.mainPhotoUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final title = p.age == null ? p.displayName : '${p.displayName}, ${p.age}';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(aspectRatio: 1, child: NetworkPhoto(url: p.mainPhotoUrl)),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineMd),
            const SizedBox(height: 4),
            Text('Va aussi à « ${widget.eventName} »', style: AppTextStyles.bodyMdMuted),
            if (p.bio != null && p.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(p.bio!, style: AppTextStyles.bodyMd),
            ],
            if (p.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.interests
                    .map((i) => Chip(label: Text(i), backgroundColor: AppColors.sidiTint, side: BorderSide.none))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            if (_matchId != null) ...[
              Text('C\'est réciproque : vous pouvez vous écrire.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.sidi)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Écrire'),
              ),
            ] else if (_sent)
              Row(children: [
                const Icon(Icons.check_circle_outline, color: AppColors.sidi),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('C\'est noté. Si cette personne vous aime aussi, la conversation s\'ouvrira dans vos messages.',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.sidi)),
                ),
              ])
            else
              ElevatedButton.icon(
                onPressed: _busy ? null : _like,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.favorite_border_rounded),
                label: const Text('J\'aimerais la connaître'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet();

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  DateTime? _startsAt;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (time == null) return;
    setState(() => _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null) {
      showSnack(context, 'Choisissez la date et l\'heure', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await EventService().createEvent(
        name: _name.text.trim(),
        venueName: _venue.text.trim(),
        city: _city.text.trim(),
        category: _category,
        description: _description.text.trim(),
        startsAt: _startsAt!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvel événement', style: AppTextStyles.headlineMd),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _venue, maxLength: 255, decoration: const InputDecoration(labelText: 'Lieu')),
              const SizedBox(height: 8),
              TextFormField(controller: _city, maxLength: 100, decoration: const InputDecoration(labelText: 'Ville')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Type (facultatif)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Choisi automatiquement')),
                  for (final entry in eventCategoryLabels.entries)
                    DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(_startsAt == null ? 'Date et heure' : formatEventDate(_startsAt)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
