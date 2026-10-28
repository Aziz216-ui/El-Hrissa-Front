import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Photo réseau avec repli propre (icône) quand l'URL est absente ou en erreur.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkPhoto({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover});

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
      imageUrl: u,
      width: width,
      height: height,
      fit: fit,
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
