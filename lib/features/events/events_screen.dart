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
      showSnack(context, wasJoined ? 'Inscription annulée' : 'Vous participez à « ${event.name} » 🎉');
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
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              icon: const Icon(Icons.add),
              label: const Text('Créer'),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        emoji: '🎉',
        title: 'Aucun événement à venir',
        subtitle: 'Les prochaines sorties organisées apparaîtront ici.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        itemCount: _events.length,
        itemBuilder: (context, index) => _buildCard(_events[index]),
      ),
    );
  }

  Widget _buildCard(EventResponse event) {
    final joined = _joined.contains(event.id);
    final busy = _busy.contains(event.id);
    return GestureDetector(
      onTap: () => _openDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(999)),
                  child: Text(formatEventDate(event.startsAt),
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
                ),
                const Spacer(),
                const Icon(Icons.people_outline, size: 18, color: AppColors.outline),
                const SizedBox(width: 4),
                Text('${event.attendeeCount}', style: AppTextStyles.labelSm),
              ],
            ),
            const SizedBox(height: 12),
            Text(event.name, style: AppTextStyles.headlineMd.copyWith(fontSize: 20)),
            if (event.venueName != null && event.venueName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.venueName!, style: AppTextStyles.bodyMdMuted)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            joined
                ? OutlinedButton.icon(
                    onPressed: busy ? null : () => _toggle(event),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Inscrit · Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: busy ? null : () => _toggle(event),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
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
        padding: const EdgeInsets.all(24),
        children: [
          Text(e.name, style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.event, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(formatEventDate(e.startsAt), style: AppTextStyles.bodyMd),
          ]),
          if (e.venueName != null && e.venueName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(e.venueName!, style: AppTextStyles.bodyMd)),
            ]),
          ],
          if (e.description != null && e.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(e.description!, style: AppTextStyles.bodyMdMuted),
          ],
          const SizedBox(height: 20),
          Text('Participants (${e.attendeeCount})', style: AppTextStyles.labelMd),
          const SizedBox(height: 10),
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
              icon: const Icon(Icons.style),
              label: const Text('Découvrir les participants'),
            ),
            const SizedBox(height: 10),
          ],
          widget.joined
              ? OutlinedButton(
                  onPressed: widget.onToggle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Annuler mon inscription'),
                )
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
                icon: const Icon(Icons.event),
                label: Text(_startsAt == null ? 'Date et heure' : formatEventDate(_startsAt)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
