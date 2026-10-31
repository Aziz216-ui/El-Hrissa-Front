import 'package:url_launcher/url_launcher.dart';

/// Ouvre une page web hors de l'app (navigateur, nouvel onglet sur le web).
/// Seuls les liens http et https sont acceptés : l'adresse vient de sources externes.
Future<bool> openExternalLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
