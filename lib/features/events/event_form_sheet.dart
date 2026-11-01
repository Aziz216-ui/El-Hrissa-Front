import 'package:flutter/material.dart';
import '../../core/models/event_models.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/state_views.dart';

/// Créer une sortie, ou modifier une des siennes (`initial`). Se ferme avec `true` si l'événement est enregistré.
class EventFormSheet extends StatefulWidget {
  final EventResponse? initial;
  const EventFormSheet({super.key, this.initial});

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _venue = TextEditingController(text: widget.initial?.venueName ?? '');
  late final _city = TextEditingController(text: widget.initial?.city ?? '');
  late final _description = TextEditingController(text: widget.initial?.description ?? '');
  late final _capacity = TextEditingController(text: widget.initial?.capacity?.toString() ?? '');
  late String? _category = widget.initial?.category;
  late DateTime? _startsAt = widget.initial?.startsAt;
  bool _saving = false;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _startsAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      // Pour une modification, la date d'origine peut être passée
      firstDate: current.isBefore(now) ? current : now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _startsAt == null ? const TimeOfDay(hour: 20, minute: 0) : TimeOfDay.fromDateTime(_startsAt!),
    );
    if (time == null) return;
    setState(() => _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null) {
      showSnack(context, 'Choisissez la date et l\'heure', error: true);
      return;
    }
    if (!_editing && _startsAt!.isBefore(DateTime.now())) {
      showSnack(context, 'La date doit être dans le futur', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      await EventService().createEvent(
        eventId: initial?.id,
        name: _name.text.trim(),
        venueName: _venue.text.trim(),
        city: _city.text.trim(),
        category: _category,
        description: _description.text.trim(),
        startsAt: _startsAt!,
        // Une modification garde l'heure de fin et la position d'origine
        endsAt: initial?.endsAt,
        latitude: initial?.latitude,
        longitude: initial?.longitude,
        capacity: int.tryParse(_capacity.text.trim()),
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
              Text(_editing ? "Modifier l'événement" : 'Nouvel événement', style: AppTextStyles.headlineMd),
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
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places (facultatif)',
                  helperText: 'Au-delà, les inscriptions vont sur une liste d\'attente. Vide = illimité.',
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final n = int.tryParse(text);
                  if (n == null || n < 1 || n > 5000) return 'Entre 1 et 5000';
                  return null;
                },
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
                    : Text(_editing ? 'Enregistrer' : 'Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
