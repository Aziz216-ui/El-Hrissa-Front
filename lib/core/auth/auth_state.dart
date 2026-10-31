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
  bool _needsIdentity = false;

  bool? get loggedIn => _loggedIn;
  bool get isOrganizer => _role?.toUpperCase() == 'ORGANISATEUR';

  /// Compte créé via Google : genre et date de naissance restent à renseigner.
  bool get needsIdentity => _needsIdentity;

  Future<void> init() async {
    final api = ApiClient();
    _loggedIn = await api.hasToken();
    _role = await api.getRole();
    _needsIdentity = _loggedIn == true && await api.getNeedsIdentity();
    notifyListeners();
  }

  void setLoggedIn({String? role, bool needsIdentity = false}) {
    _loggedIn = true;
    _role = role;
    _needsIdentity = needsIdentity;
    notifyListeners();
  }

  Future<void> setIdentityCompleted() async {
    _needsIdentity = false;
    await ApiClient().setNeedsIdentity(false);
    notifyListeners();
  }

  void setLoggedOut() {
    if (_loggedIn == false) return;
    _loggedIn = false;
    _role = null;
    _needsIdentity = false;
    notifyListeners();
  }
}
