import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// « Se souvenir de moi » : l'email est gardé partout ; le mot de passe seulement dans l'app mobile,
/// où le stockage est chiffré par le système (Keystore Android). Sur le web, il n'est jamais gardé
/// (le navigateur n'a pas de coffre sûr) : c'est le gestionnaire de mots de passe du navigateur qui s'en charge.
class RememberedLogin {
  final String email;
  final String password;
  const RememberedLogin(this.email, this.password);

  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'remembered_email';
  static const _passwordKey = 'remembered_password';

  static Future<RememberedLogin?> load() async {
    try {
      final email = await _storage.read(key: _emailKey);
      if (email == null || email.isEmpty) return null;
      final password =
          kIsWeb ? '' : (await _storage.read(key: _passwordKey) ?? '');
      return RememberedLogin(email, password);
    } catch (_) {
      return null; // stockage indisponible (navigation privée, tests)
    }
  }

  static Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      if (!kIsWeb) await _storage.write(key: _passwordKey, value: password);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (_) {}
  }
}
