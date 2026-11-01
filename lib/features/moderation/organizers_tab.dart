import 'package:flutter/material.dart';
import '../../core/models/organizer_request_models.dart';
import '../../core/services/organizer_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/utils/link_opener.dart';
import '../../shared/widgets/state_views.dart';

/// Demandes pour devenir organisateur : on accepte (le rôle est accordé) ou on refuse avec un motif.
class OrganizersTab extends StatefulWidget {
  const OrganizersTab({super.key});

  @override
  State<OrganizersTab> createState() => _OrganizersTabState();
}

class _OrganizersTabState extends State<OrganizersTab> {
  final _service = OrganizerRequestService();
  List<OrganizerRequestItem> _items = [];
  bool _loading = true;
  String? _error;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listPending();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(OrganizerRequestItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accepter cette demande ?'),
        content: Text('${item.userName} pourra créer des événements au nom de « ${item.organizationName} ».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accepter')),
        ],
      ),
    );
    if (ok != true) return;
    await _decide(item, () => _service.approve(item.id), 'Demande acceptée');
  }

  Future<void> _reject(OrganizerRequestItem item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser cette demande'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Motif (la personne le verra)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length >= 3) Navigator.pop(ctx, text);
            },
            child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    await _decide(item, () => _service.reject(item.id, reason), 'Demande refusée');
  }

  Future<void> _decide(OrganizerRequestItem item, Future<void> Function() action, String doneMessage) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      await action();
      if (!mounted) return;
      showSnack(context, doneMessage);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyView(
        icon: Icons.celebration_outlined,
        title: 'Aucune demande en attente',
        subtitle: 'Les demandes pour devenir organisateur apparaissent ici.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(OrganizerRequestItem item) {
    final busy = _busy.contains(item.id);
    final link = item.link;
    final isWebLink = link != null && (link.startsWith('http://') || link.startsWith('https://'));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.organizationName, style: AppTextStyles.titleMd),
          const SizedBox(height: 2),
          Text('${item.userName} · ${item.email}', style: AppTextStyles.labelMd),
          const SizedBox(height: 2),
          Text('Tél. ${item.phone}', style: AppTextStyles.labelMd),
          if (link != null && link.isNotEmpty) ...[
            const SizedBox(height: 2),
            isWebLink
                ? InkWell(
                    onTap: () => openExternalLink(link),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(link, style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, decoration: TextDecoration.underline)),
                    ),
                  )
                : Text(link, style: AppTextStyles.labelMd),
          ],
          const SizedBox(height: 8),
          Text(item.description, style: AppTextStyles.bodyMd),
          if (item.submittedAt != null) ...[
            const SizedBox(height: 6),
            Text('Reçue le ${formatEventDate(item.submittedAt)}', style: AppTextStyles.labelSm),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _reject(item),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : () => _approve(item),
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
