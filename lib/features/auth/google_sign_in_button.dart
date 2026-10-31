import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

/// « Continuer avec Google » : récupère nom, prénom et email du compte Gmail, puis connecte
/// ou crée le compte. Le routeur envoie ensuite vers /complete-identity si le genre et la date
/// de naissance manquent.
class GoogleSignInButton extends StatefulWidget {
  final ValueChanged<String> onError;
  const GoogleSignInButton({super.key, required this.onError});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final auth = await _authService.loginWithGoogle();
      if (auth != null && mounted) context.go('/home');
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bouton plein, sans cadre : un aplat gris clair, comme les autres boutons secondaires
    return ElevatedButton.icon(
      onPressed: _loading ? null : _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceLow,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      icon: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          : const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
      label: const Text('Continuer avec Google'),
    );
  }
}
