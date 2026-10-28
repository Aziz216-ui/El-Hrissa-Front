# El-Hrissa : front (Flutter)

Application mobile et web **Elahrisa** (rencontres et événements en Tunisie), écrite en **Flutter**. Elle consomme l'API du dépôt [El-Hrissa](https://github.com/Aziz216-ui/El-Hrissa) (backend Spring Boot).

## Fonctionnalités

- Inscription, connexion, déconnexion automatique si la session expire
- **Swipe** de profils autour de soi (GPS ou Tunis par défaut), filtres distance et âge, détection de match
- **Matchs et chat** avec rafraîchissement automatique, signalement, blocage et suppression de match
- **Événements** : liste, détail et participants, inscription ou désistement, découverte des autres participants ; création et suppression pour les comptes organisateurs
- **Profil** : bio, intérêts, préférence de rencontre, gestion des photos, mise à jour de la position, vérification par selfie, liste des utilisateurs bloqués
- **Notifications** avec compteur de non lus

## Prérequis

- Flutter 3.x (Dart ≥ 3.3) : `flutter doctor`
- Le backend démarré (voir son README), par défaut sur le port 8086

## Lancer l'application

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8086
```

L'URL de l'API se règle avec `--dart-define=API_BASE_URL=...`. Sans cette option :

| Plateforme | URL utilisée |
|---|---|
| Web, iOS simulateur, desktop | `http://localhost:8086` |
| Émulateur Android | `http://10.0.2.2:8086` |
| **Téléphone réel** | à fournir : `--dart-define=API_BASE_URL=http://<IP-de-votre-PC>:8086` (même réseau Wi-Fi) |

En production, utilisez une URL **HTTPS**.

## Tests

```bash
flutter analyze
flutter test                      # test de démarrage (redirection vers la connexion)

# Test de contrat : exécute les vrais services contre un backend local
flutter test test/api_contract_test.dart --dart-define=API_BASE_URL=http://localhost:8086
```

Sans `API_BASE_URL` ou sans backend joignable, le test de contrat est ignoré au lieu d'échouer. Il crée des comptes de test dans la base visée : ne le lancez pas contre une base de production.

## Build

```bash
flutter build web --release --dart-define=API_BASE_URL=https://votre-api.example.com
```

Le dépôt ne contient pas encore les dossiers `android/` et `ios/`. Pour compiler un APK ou une app iOS :

```bash
flutter create --platforms=android,ios .
```

puis déclarer les permissions **localisation** et **caméra** (`AndroidManifest.xml` et `Info.plist`), nécessaires au GPS, à la photo de profil et au selfie de vérification.

## Structure

```
lib/
  main.dart            routes (go_router) et garde d'authentification
  core/
    api/               client Dio, endpoints, traduction des erreurs
    auth/              état de session
    models/            modèles alignés sur les DTO du backend
    services/          un service par domaine (auth, profil, swipe, chat, événements...)
    theme/             couleurs, typographies, thème
  features/            écrans : auth, home, swipe, chat, events, profile, notifications
  shared/              widgets et utilitaires communs
test/                  smoke test et test de contrat
```

## Limites connues

- Chat en polling (toutes les 4 s) : pas de temps réel ni de notifications push côté serveur.
- Pas de « mot de passe oublié » ni de suppression de compte.
- La modération (signalements, validation des selfies) existe dans l'API mais pas encore dans l'application.
- Les interfaces n'ont pas encore été validées sur appareil : à vérifier manuellement avant publication.
