import 'package:flutter/material.dart';
import '../../core/services/organizer_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/state_views.dart';

/// Les quatre champs de la demande, partagés entre l'inscription et le profil.
class OrganizerFormControllers {
  final name = TextEditingController();
  final phone = TextEditingController();
  final link = TextEditingController();
  final description = TextEditingController();

  void dispose() {
    name.dispose();
    phone.dispose();
    link.dispose();
    description.dispose();
  }

  Future<void> submit() => OrganizerRequestService().submit(
        organizationName: name.text.trim(),
        phone: phone.text.trim(),
        link: link.text.trim(),
        description: description.text.trim(),
      );
}

/// À placer dans un Form : la validation se fait avec celle du formulaire parent.
class OrganizerFormFields extends StatelessWidget {
  final OrganizerFormControllers controllers;
  const OrganizerFormFields({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controllers.name,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Nom de l'organisation ou du club", helperText: 'Affiché sur votre page publique'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controllers.phone,
          maxLength: 30,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Téléphone', helperText: "Pour que l'équipe puisse vous joindre"),
          validator: (v) => v == null || v.trim().length < 8 ? 'Numéro invalide' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controllers.link,
          maxLength: 300,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Lien Instagram, Facebook ou site (facultatif)'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controllers.description,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Qu'organisez-vous ?", helperText: 'Soirées, sorties, ateliers...'),
          validator: (v) => v == null || v.trim().length < 10 ? 'Au moins 10 caractères' : null,
        ),
      ],
    );
  }
}

/// Feuille « Devenir organisateur » depuis le profil. Se ferme avec `true` si la demande est envoyée.
class OrganizerRequestSheet extends StatefulWidget {
  /// Motif du refus précédent, s'il y en a un.
  final String? rejectReason;
  const OrganizerRequestSheet({super.key, this.rejectReason});

  @override
  State<OrganizerRequestSheet> createState() => _OrganizerRequestSheetState();
}

class _OrganizerRequestSheetState extends State<OrganizerRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = OrganizerFormControllers();
  bool _sending = false;

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await _controllers.submit();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Devenir organisateur', style: AppTextStyles.headlineMd),
              const SizedBox(height: 8),
              Text(
                "Un modérateur examine votre demande. Tant qu'elle n'est pas acceptée, vous utilisez l'app comme visiteur.",
                style: AppTextStyles.bodyMdMuted,
              ),
              if (widget.rejectReason != null && widget.rejectReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(AppRadius.control)),
                  child: Text('Dernière demande refusée : ${widget.rejectReason}',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
                ),
              ],
              const SizedBox(height: 16),
              OrganizerFormFields(controllers: _controllers),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
