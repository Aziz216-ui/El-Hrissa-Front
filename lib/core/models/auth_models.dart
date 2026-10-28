class AuthResponse {
  final String token;
  final String tokenType;
  final int expiresInMs;
  final UserResponse user;

  AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresInMs,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresInMs: json['expiresInMs'] ?? 0,
      user: UserResponse.fromJson(json['user'] ?? {}),
    );
  }
}

class UserResponse {
  final int? id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? role;
  final String? gender;
  final bool emailVerified;

  UserResponse({
    this.id,
    this.nom,
    this.prenom,
    this.email,
    this.role,
    this.gender,
    this.emailVerified = false,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      // Le backend sérialise l'identifiant sous "idClient"
      id: (json['idClient'] ?? json['id']) as int?,
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      role: json['role'],
      gender: json['gender'],
      emailVerified: json['emailVerified'] ?? false,
    );
  }
}
