import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/harissa_shell.dart';
import 'google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  static const _storage = FlutterSecureStorage();
  static const _rememberedEmailKey = 'remembered_email';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  /// Le mot de passe n'est jamais gardé par l'app : seul l'email est retenu,
  /// et le gestionnaire de mots de passe du téléphone ou du navigateur remplit le reste.
  Future<void> _loadRememberedEmail() async {
    try {
      final email = await _storage.read(key: _rememberedEmailKey);
      if (!mounted || email == null || email.isEmpty) return;
      if (_emailController.text.isEmpty) _emailController.text = email;
    } catch (_) {
      // stockage indisponible (navigation privée, tests) : on laisse le champ vide
    }
  }

  Future<void> _saveRememberedEmail() async {
    try {
      if (_rememberMe) {
        await _storage.write(
            key: _rememberedEmailKey, value: _emailController.text.trim());
      } else {
        await _storage.delete(key: _rememberedEmailKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      await _saveRememberedEmail();
      // Indique au système que la connexion a réussi : il propose d'enregistrer le mot de passe
      TextInput.finishAutofillContext();
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
    return HarissaShell(
      // « Nawwart » : l'expression tunisienne pour dire à quelqu'un qu'il illumine l'endroit
      arabic: 'نوّرت',
      title: 'Connexion',
      onBack: () => context.go('/welcome'),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                FormErrorBox(_errorMessage!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'Adresse email',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: AppColors.outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: AppColors.outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.outline,
                    ),
                    tooltip: _obscurePassword
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre mot de passe';
                  }
                  return null;
                },
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Text('Se souvenir de moi',
                              style: AppTextStyles.bodyMd),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/forgot-password',
                        extra: _emailController.text.trim()),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Se connecter'),
              ),
              const SizedBox(height: 14),
              GoogleSignInButton(
                  onError: (m) => setState(() => _errorMessage = m)),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Pas encore de compte ?',
                      style: AppTextStyles.bodyMdMuted),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Créer un compte'),
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
