import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../auth/auth_state.dart';
import '../push/push_service.dart';
import '../auth/remembered_login.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _api.dio.post(
        Endpoints.login,
        data: {'email': email.trim(), 'password': password},
      );
      return await _startSession(AuthResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur de connexion'));
    }
  }

  Future<AuthResponse> register({
    required int cin,
    required String nom,
    required String prenom,
    required String dateNaissance, // YYYY-MM-DD
    required String gender, // MEN | WOMEN
    required String email,
    required String password,
    String role = 'USER',
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.register,
        data: {
          'cin': cin,
          'nom': nom.trim(),
          'prenom': prenom.trim(),
          'dateNaissance': dateNaissance,
          'gender': gender,
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      );
      return await _startSession(AuthResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Erreur lors de l'inscription"));
    }
  }

  /// Client ID OAuth « web » du projet Google Cloud (sert de serverClientId pour obtenir l'idToken) :
  ///   flutter run --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    // Client ID « Web » (public, ce n'est pas un secret) : l'idToken est émis pour cette audience
    defaultValue: '145076283226-o8m3g27a5cia5durlfd2or6foh82fsbq.apps.googleusercontent.com',
  );

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb && _googleClientId.isNotEmpty ? _googleClientId : null,
    serverClientId: !kIsWeb && _googleClientId.isNotEmpty ? _googleClientId : null,
  );

  /// Ouvre le sélecteur de compte Google ; null si l'utilisateur annule.
  /// Le backend vérifie le jeton, puis connecte ou crée le compte (nom, prénom et email viennent de Google).
  Future<AuthResponse?> loginWithGoogle() async {
    if (_googleClientId.isEmpty) {
      throw Exception("Connexion Google non configurée (GOOGLE_CLIENT_ID manquant)");
    }
    try {
      await _googleSignIn.signOut(); // force le choix du compte
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      // Mobile : idToken. Web : Google ne le renvoie pas, le backend vérifie alors le jeton d'accès.
      if (auth.idToken == null && auth.accessToken == null) {
        throw Exception("Google n'a fourni aucun jeton");
      }
      final response = await _api.dio.post(
        Endpoints.google,
        data: {'idToken': auth.idToken, 'accessToken': auth.accessToken},
      );
      return await _startSession(AuthResponse.fromJson(response.data));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Connexion Google impossible'));
    }
  }

  /// Genre et date de naissance (YYYY-MM-DD) d'un compte Google.
  Future<void> completeIdentity({required String dateNaissance, required String gender}) async {
    try {
      await _api.dio.put(Endpoints.completeIdentity, data: {'dateNaissance': dateNaissance, 'gender': gender});
      await AuthState.instance.setIdentityCompleted();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'enregistrer vos informations"));
    }
  }

  Future<AuthResponse> _startSession(AuthResponse auth) async {
    final needsIdentity = auth.user.gender == null || auth.user.gender!.isEmpty;
    await _api.saveSession(auth.token, auth.user.id, auth.user.role, needsIdentity: needsIdentity);
    AuthState.instance.setLoggedIn(role: auth.user.role, needsIdentity: needsIdentity);
    return auth;
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _api.dio.post(Endpoints.resendVerification);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer l'email"));
    }
  }

  /// Le backend répond toujours 204, que l'adresse soit connue ou non.
  Future<void> forgotPassword(String email) async {
    try {
      await _api.dio.post(Endpoints.forgotPassword, data: {'email': email.trim()});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer l'email"));
    }
  }

  /// Supprime définitivement le compte connecté (profil, photos, matchs, messages...), puis déconnecte.
  Future<void> deleteMyAccount() async {
    final id = await _api.getUserId();
    if (id == null) throw Exception('Session introuvable, reconnectez-vous');
    try {
      await _api.dio.delete(Endpoints.user(id));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de supprimer le compte'));
    }
    await RememberedLogin.clear();
    await logout();
  }

  Future<void> logout() async {
    // Avant d'effacer la session : le serveur doit encore nous reconnaître pour retirer ce téléphone
    await PushService.instance.unregister().timeout(const Duration(seconds: 4), onTimeout: () {});
    await _api.clearToken();
    AuthState.instance.setLoggedOut();
  }

  Future<int?> getCurrentUserId() => _api.getUserId();
}
