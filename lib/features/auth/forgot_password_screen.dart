import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/state_views.dart';

/// Demande d'un lien de réinitialisation. Le message de confirmation est le même que l'adresse
/// existe ou non (le backend ne révèle pas quels emails sont inscrits).
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.initialEmail);
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().forgotPassword(_emailController.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.go('/login'),
        ),
        title: Text('Mot de passe oublié', style: AppTextStyles.headlineMd),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _sent ? _buildConfirmation() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saisissez l\'adresse email de votre compte. Nous vous enverrons un lien pour choisir un nouveau mot de passe.',
            style: AppTextStyles.bodyMdMuted,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'Adresse email',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Veuillez saisir votre email';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: 20),
        Text('Vérifiez votre boîte mail', style: AppTextStyles.headlineMd, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Si un compte existe pour ${_emailController.text.trim()}, un lien de réinitialisation vient d\'être envoyé. '
          'Il est valable 1 heure. Pensez à regarder dans vos indésirables.',
          style: AppTextStyles.bodyMdMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Retour à la connexion')),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Utiliser une autre adresse'),
        ),
      ],
    );
  }
}
