import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/harissa_shell.dart';
import '../../shared/widgets/state_views.dart';
import '../legal/legal_screen.dart';
import '../organizer/organizer_request_form.dart';
import 'google_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cinController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  DateTime _dateNaissance = DateTime(2000, 1, 1);
  String _selectedGender = 'MEN'; // 'MEN' or 'WOMEN'
  final _organizerForm = OrganizerFormControllers();
  bool _wantsOrganizer = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _cinController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _organizerForm.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans min
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formattedDate =
          '${_dateNaissance.year.toString().padLeft(4, '0')}-${_dateNaissance.month.toString().padLeft(2, '0')}-${_dateNaissance.day.toString().padLeft(2, '0')}';

      await _authService.register(
        cin: int.parse(_cinController.text.trim()),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        dateNaissance: formattedDate,
        gender: _selectedGender,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Organisateur : le compte est créé comme visiteur, la demande part ensuite pour examen
      String? organizerNote;
      if (_wantsOrganizer) {
        try {
          await _organizerForm.submit();
          organizerNote = "Compte créé. Votre demande d'organisateur est en cours d'examen.";
        } catch (_) {
          organizerNote = "Compte créé, mais la demande d'organisateur n'est pas partie : refaites-la depuis votre profil.";
        }
      }

      if (mounted) {
        if (organizerNote != null) showSnack(context, organizerNote);
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HarissaShell(
      // « Yalla, hayya binna » : allons-y
      arabic: '\u0647\u064a\u0627 \u0628\u064a\u0646\u0627',
      title: 'Créer un compte',
      onBack: () => context.go('/welcome'),
      child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _RoleChoice(
                  wantsOrganizer: _wantsOrganizer,
                  onChanged: (value) => setState(() => _wantsOrganizer = value),
                ),
                if (_wantsOrganizer) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Un modérateur examine votre demande avant de vous donner accès à la création d'événements. "
                    "En attendant, vous utilisez l'app comme visiteur.",
                    style: AppTextStyles.labelMd,
                  ),
                  const SizedBox(height: 12),
                  OrganizerFormFields(controllers: _organizerForm),
                ],
                const SizedBox(height: 20),

                // Prénom & Nom
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(hintText: 'Prénom'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(hintText: 'Nom'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CIN
                TextFormField(
                  controller: _cinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Numéro CIN (8 chiffres)',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Veuillez renseigner votre CIN';
                    if (int.tryParse(v) == null) return 'CIN invalide (chiffres uniquement)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date de naissance
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Date de naissance : ${_dateNaissance.day.toString().padLeft(2, '0')}/${_dateNaissance.month.toString().padLeft(2, '0')}/${_dateNaissance.year}',
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                        const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Genre
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Genre : ', style: AppTextStyles.labelMd),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Homme'),
                      selected: _selectedGender == 'MEN',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedGender = 'MEN');
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedGender == 'MEN' ? AppColors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Femme'),
                      selected: _selectedGender == 'WOMEN',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedGender = 'WOMEN');
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedGender == 'WOMEN' ? AppColors.white : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.outline),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe (8 car. min)',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 8 ? '8 caractères minimum' : null,
                ),
                const SizedBox(height: 20),
                const LegalLinks(align: TextAlign.start),
                const SizedBox(height: 12),

                // Bouton S'inscrire
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 16),

                GoogleSignInButton(onError: (m) => setState(() => _errorMessage = m)),
                const SizedBox(height: 16),

                // Lien vers Login
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Vous avez déjà un compte ?', style: AppTextStyles.bodyMdMuted),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
      ),
    );
  }
}


/// « Je cherche des sorties » ou « J'organise des sorties » : deux grandes cartes à choisir.
class _RoleChoice extends StatelessWidget {
  final bool wantsOrganizer;
  final ValueChanged<bool> onChanged;
  const _RoleChoice({required this.wantsOrganizer, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight : les deux cartes ont la même hauteur, même dans une page qui défile
    return IntrinsicHeight(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _card(
            icon: Icons.favorite_border_rounded,
            title: 'Visiteur',
            subtitle: 'Je cherche des sorties et des rencontres',
            selected: !wantsOrganizer,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _card(
            icon: Icons.celebration_outlined,
            title: 'Organisateur',
            subtitle: "J'organise des sorties ou des événements",
            selected: wantsOrganizer,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    ));
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title : $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.pastelPink : AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(title, style: AppTextStyles.titleMd.copyWith(fontSize: 16, color: selected ? AppColors.primary : AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
