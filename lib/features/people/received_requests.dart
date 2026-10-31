import 'package:flutter/material.dart';
import '../../core/models/people_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/network_photo.dart';

/// Les personnes qui ont envoyé une demande : on les accepte (la conversation s'ouvre) ou on les refuse.
class ReceivedRequestsSection extends StatelessWidget {
  final List<ConnectionRequest> requests;
  final Set<int> busy;
  final ValueChanged<ConnectionRequest> onAccept;
  final ValueChanged<ConnectionRequest> onDecline;

  const ReceivedRequestsSection({
    super.key,
    required this.requests,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Demandes (${requests.length})', style: AppTextStyles.titleMd),
        ),
        const SizedBox(height: 10),
        for (final request in requests) ...[
          _RequestTile(
            request: request,
            busy: busy.contains(request.profile.userId),
            onAccept: () => onAccept(request),
            onDecline: () => onDecline(request),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ConnectionRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({required this.request, required this.busy, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final profile = request.profile;
    final title = profile.age == null ? profile.displayName : '${profile.displayName}, ${profile.age}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.pastelPink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(url: profile.mainPhotoUrl, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMd.copyWith(fontSize: 17)),
                    Text('aimerait faire votre connaissance', style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: busy ? null : onDecline,
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Accepter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
