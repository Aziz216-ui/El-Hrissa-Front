import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran d'erreur avec bouton « Réessayer ».
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _IconBadge(icon: Icons.wifi_off_rounded, color: AppColors.onSurfaceVariant, tint: AppColors.surfaceContainer),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMdMuted, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide (aucune donnée) : dit ce qui manque et propose une action.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: icon, color: AppColors.primary, tint: AppColors.pastelPink),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headlineMd, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodyMdMuted, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icône dans une arche teintée : même forme que le logo.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  const _IconBadge({required this.icon, required this.color, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 96,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(42),
          topRight: Radius.circular(42),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      alignment: const Alignment(0, 0.15),
      child: Icon(icon, size: 36, color: color),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.onSurface,
      behavior: SnackBarBehavior.floating,
    ));
}

String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
