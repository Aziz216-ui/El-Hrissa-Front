import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

/// État de session partagé : le routeur l'écoute pour rediriger vers /login
/// (déconnexion, token expiré) ou /home (connecté).
class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._();
  AuthState._();

  /// null tant que le token stocké n'a pas été lu.
  bool? _loggedIn;
  String? _role;

  bool? get loggedIn => _loggedIn;
  bool get isOrganizer => _role?.toUpperCase() == 'ORGANISATEUR';

  Future<void> init() async {
    final api = ApiClient();
    _loggedIn = await api.hasToken();
    _role = await api.getRole();
    notifyListeners();
  }

  void setLoggedIn({String? role}) {
    _loggedIn = true;
    _role = role;
    notifyListeners();
  }

  void setLoggedOut() {
    if (_loggedIn == false) return;
    _loggedIn = false;
    _role = null;
    notifyListeners();
  }
}
