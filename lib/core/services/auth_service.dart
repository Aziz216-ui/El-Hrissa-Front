import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../auth/auth_state.dart';
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

  Future<AuthResponse> _startSession(AuthResponse auth) async {
    await _api.saveSession(auth.token, auth.user.id, auth.user.role);
    AuthState.instance.setLoggedIn(role: auth.user.role);
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
    await logout();
  }

  Future<void> logout() async {
    await _api.clearToken();
    AuthState.instance.setLoggedOut();
  }

  Future<int?> getCurrentUserId() => _api.getUserId();
}
