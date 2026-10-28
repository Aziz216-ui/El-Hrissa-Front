import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/models/event_models.dart';
import '../../core/models/profile_models.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _service = EventService();
  List<EventResponse> _events = [];
  Set<int> _joined = {};
  bool _isLoading = true;
  String? _error;
  final Set<int> _busy = {};

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
      final results = await Future.wait([_service.getEvents(), _service.getJoinedEventIds()]);
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
      showSnack(context, wasJoined ? 'Inscription annulée' : 'Vous participez à « ${event.name} »');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(event.id));
    }
  }

  Future<void> _createEvent() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateEventSheet(),
    );
    if (created == true) _load();
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
        canDelete: AuthState.instance.isOrganizer,
        onToggle: () {
          Navigator.pop(context);
          _toggle(event);
        },
        onDelete: () => _deleteEvent(event),
        onDiscover: () {
          Navigator.pop(context);
          context.push('/swipe?eventId=${event.id}');
        },
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Événements', style: AppTextStyles.headlineLgMobile),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const ElBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_events.isEmpty) {
      return const EmptyView(
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
    final hasVenue = event.venueName != null && event.venueName!.isNotEmpty;
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
                          if (hasVenue) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 16, color: AppColors.sidi),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.venueName!,
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
                ),
                const SizedBox(height: 14),
                joined
                    ? OutlinedButton.icon(
                        onPressed: busy ? null : () => _toggle(event),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Inscrit · Annuler'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: busy ? null : () => _toggle(event),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("S'inscrire"),
                      ),
              ],
            ),
          ),
        ),
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

  const _EventDetailSheet({
    required this.event,
    required this.joined,
    required this.canDelete,
    required this.onToggle,
    required this.onDelete,
    required this.onDiscover,
  });

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  List<PublicProfileResponse>? _attendees;

  @override
  void initState() {
    super.initState();
    EventService().getAttendees(widget.event.id).then((a) {
      if (mounted) setState(() => _attendees = a);
    }).catchError((_) {
      if (mounted) setState(() => _attendees = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
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
                    if (e.venueName != null && e.venueName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 18, color: AppColors.sidi),
                        const SizedBox(width: 4),
                        Expanded(child: Text(e.venueName!, style: AppTextStyles.bodyMd)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (e.description != null && e.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(e.description!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
          const SizedBox(height: 24),
          Text('Participants (${e.attendeeCount})', style: AppTextStyles.titleMd.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          if (_attendees == null)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_attendees!.isEmpty)
            Text('Soyez le premier à vous inscrire !', style: AppTextStyles.bodyMdMuted)
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _attendees!
                  .map((a) => Column(children: [
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
                      ]))
                  .toList(),
            ),
          const SizedBox(height: 24),
          if (widget.joined) ...[
            ElevatedButton.icon(
              onPressed: widget.onDiscover,
              icon: const Icon(Icons.style_rounded),
              label: const Text('Découvrir les participants'),
            ),
            const SizedBox(height: 10),
          ],
          widget.joined
              ? OutlinedButton(onPressed: widget.onToggle, child: const Text('Annuler mon inscription'))
              : ElevatedButton(onPressed: widget.onToggle, child: const Text("S'inscrire")),
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
  final _description = TextEditingController();
  DateTime? _startsAt;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
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
