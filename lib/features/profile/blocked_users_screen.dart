import 'package:flutter/material.dart';
import '../../core/models/notification_models.dart';
import '../../core/services/safety_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/state_views.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _service = SafetyService();
  List<BlockedUser> _users = [];
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
      final users = await _service.getBlocked();
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    try {
      await _service.unblock(user.userId);
      if (mounted) {
        showSnack(context, '${user.fullName} a été débloqué(e)');
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Utilisateurs bloqués', style: AppTextStyles.headlineMd)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _users.isEmpty
                  ? const EmptyView(
                      icon: Icons.shield_outlined,
                      title: 'Personne n\'est bloqué',
                      subtitle: 'Les profils que vous bloquez apparaîtront ici.',
                    )
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceContainer,
                            child: Icon(Icons.person, color: AppColors.outline),
                          ),
                          title: Text(u.fullName.isEmpty ? 'Utilisateur' : u.fullName),
                          trailing: TextButton(onPressed: () => _unblock(u), child: const Text('Débloquer')),
                        );
                      },
                    ),
    );
  }
}
