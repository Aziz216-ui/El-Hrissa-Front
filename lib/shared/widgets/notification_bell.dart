import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Cloche avec compteur de notifications non lues ; ouvre /notifications.
class NotificationBell extends StatefulWidget {
  /// Sur la bande rouge : icône blanche et pastille blanche.
  final bool onBand;
  const NotificationBell({super.key, this.onBand = false});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _service = NotificationService();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await _service.getUnreadCount();
    if (mounted) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.onBand ? AppColors.white : AppColors.onSurface;
    final badgeColor = widget.onBand ? AppColors.white : AppColors.primary;
    final badgeText = widget.onBand ? AppColors.primary : AppColors.white;
    return Semantics(
      button: true,
      label: _unread > 0 ? 'Notifications, $_unread non lues' : 'Notifications',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () async {
          await context.push('/notifications');
          _refresh();
        },
        radius: 26,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, color: iconColor, size: 26),
              if (_unread > 0)
                Positioned(
                  right: 4,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      _unread > 99 ? '99+' : '$_unread',
                      style: AppTextStyles.labelSm.copyWith(color: badgeText, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
