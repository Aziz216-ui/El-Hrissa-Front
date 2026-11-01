import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/image_url.dart';

/// Photo réseau avec repli propre (icône) quand l'URL est absente ou en erreur.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Largeur demandée au serveur d'images (pixels). Par défaut : trois fois la largeur affichée, ou 900.
  final int? maxWidth;

  const NetworkPhoto({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover, this.maxWidth});

  /// Adresse réellement chargée : une version réduite des photos Cloudinary.
  static String sourceFor(String url, {double? width, int? maxWidth}) {
    final target = maxWidth ?? ((width != null && width.isFinite) ? (width * 3).round().clamp(120, 1200) : 900);
    return optimizedImageUrl(url, width: target);
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceContainer,
        child: const Center(child: Icon(Icons.person, color: AppColors.outline, size: 48)),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: sourceFor(u, width: width, maxWidth: maxWidth),
      width: width,
      height: height,
      fit: fit,
      // Sur le web, le mode <img> par défaut s'affiche en noir / échoue : on télécharge les octets.
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      placeholder: (_, __) => Container(width: width, height: height, color: AppColors.surfaceLow),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }
}

/// Avatar rond avec repli.
class UserAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const UserAvatar({super.key, required this.url, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: NetworkPhoto(url: url, width: radius * 2, height: radius * 2),
      ),
    );
  }
}

/// Charge une photo à l'avance pour qu'elle s'affiche tout de suite quand la carte arrive.
/// Les erreurs sont ignorées : ce n'est qu'un coup de pouce.
Future<void> precacheNetworkPhoto(BuildContext context, String? url, {double? width, int? maxWidth}) async {
  if (url == null || url.isEmpty) return;
  try {
    await precacheImage(
      CachedNetworkImageProvider(
        NetworkPhoto.sourceFor(url, width: width, maxWidth: maxWidth),
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      ),
      context,
    );
  } catch (_) {}
}
