import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/notification_models.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationResponse> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.getNotifications();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Future<void> _open(NotificationResponse n) async {
    if (!n.read) {
      try {
        await _service.markRead(n.id);
      } catch (_) {}
    }
    if (!mounted) return;
    // NEW_MATCH / NEW_MESSAGE : les deux mènent à la liste des conversations
    context.go('/chat');
  }

  IconData _icon(String type) => type == 'NEW_MATCH' ? Icons.favorite : Icons.chat_bubble;

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.read);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.headlineMd),
        actions: [
          if (hasUnread) TextButton(onPressed: _markAllRead, child: const Text('Tout lire')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyView(
        icon: Icons.notifications_none_rounded,
        title: 'Rien pour le moment',
        subtitle: 'Vous serez prévenu(e) ici de vos nouveaux matchs et messages.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
        itemBuilder: (context, i) {
          final n = _items[i];
          return ListTile(
            tileColor: n.read ? null : AppColors.pastelPink.withValues(alpha: 0.4),
            leading: CircleAvatar(
              backgroundColor: AppColors.pastelPink,
              child: Icon(_icon(n.type), color: AppColors.primary, size: 20),
            ),
            title: Text(n.content, style: AppTextStyles.bodyMd.copyWith(fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
            subtitle: Text(formatRelative(n.createdAt), style: AppTextStyles.labelSm),
            onTap: () => _open(n),
          );
        },
      ),
    );
  }
}
