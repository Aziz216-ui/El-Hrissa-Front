import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../legal/legal_screen.dart';

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

      if (mounted) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          tooltip: 'Retour',
          onPressed: () => context.go('/welcome'),
        ),
        title: Text('Créer un compte', style: AppTextStyles.headlineMd),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        Text(
                          'Date de naissance : ${_dateNaissance.day.toString().padLeft(2, '0')}/${_dateNaissance.month.toString().padLeft(2, '0')}/${_dateNaissance.year}',
                          style: AppTextStyles.bodyMd,
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Genre
                Row(
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

                // Lien vers Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Vous avez déjà un compte ? ', style: AppTextStyles.bodyMd),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('Se connecter', style: AppTextStyles.labelMdPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
