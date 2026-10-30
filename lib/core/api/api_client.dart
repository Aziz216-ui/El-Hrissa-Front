import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_state.dart';
import 'endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'user_role';

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 100),
        receiveTimeout: const Duration(seconds: 100),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Token expiré ou invalide : on déconnecte (le routeur renvoie vers /login).
          // Un 401 sur /login signifie « mauvais mot de passe », pas une session expirée.
          final isAuthCall = error.requestOptions.path == Endpoints.login ||
              error.requestOptions.path == Endpoints.register;
          final unauthorized = error.response?.statusCode == 401 ||
              (error.response?.statusCode == 403 && await hasToken() && error.response?.data is! Map);
          if (unauthorized && !isAuthCall && await hasToken()) {
            await clearToken();
            AuthState.instance.setLoggedOut();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveSession(String token, int? userId, String? role) async {
    await _storage.write(key: _tokenKey, value: token);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId.toString());
    if (role != null) await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<String?> getRole() => _storage.read(key: _roleKey);
}
