import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/models/moderation_models.dart';
import '../../core/models/profile_models.dart';
import '../../core/services/moderation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/state_views.dart';

/// Espace de modération des organisateurs : signalements et selfies de vérification.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Modération', style: AppTextStyles.headlineMd),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Signalements'), Tab(text: 'Vérifications')],
          ),
        ),
        body: const TabBarView(children: [_ReportsTab(), _VerificationsTab()]),
      ),
    );
  }
}

/// Liste rechargeable commune aux deux onglets.
abstract class _LoadableState<T extends StatefulWidget, I> extends State<T> {
  final service = ModerationService();
  List<I> items = [];
  bool isLoading = true;
  String? error;

  Future<List<I>> fetch();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await fetch();
      if (mounted) setState(() => items = result);
    } catch (e) {
      if (mounted) setState(() => error = cleanError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildList({
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(I item) itemBuilder,
  }) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (error != null) return ErrorView(message: error!, onRetry: load);
    if (items.isEmpty) return EmptyView(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => itemBuilder(items[i]),
      ),
    );
  }
}

/// Demande une note facultative avant de valider une décision.
Future<String?> _askNotes(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'Note interne (facultatif)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Valider')),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Signalements

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends _LoadableState<_ReportsTab, ReportItem> {
  @override
  Future<List<ReportItem>> fetch() => service.getReports(status: 'PENDING');

  Future<void> _decide(ReportItem report) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Décision pour ${report.reportedName}', style: AppTextStyles.labelMd),
            ),
            for (final entry in reportDecisions.entries)
              ListTile(
                leading: Icon(
                  entry.key == 'ACTION_TAKEN' ? Icons.block : Icons.check_circle_outline,
                  color: entry.key == 'ACTION_TAKEN' ? AppColors.error : AppColors.onSurfaceVariant,
                ),
                title: Text(entry.value),
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );
    if (status == null || !mounted) return;
    final notes = await _askNotes(context, reportDecisions[status]!);
    if (notes == null) return;
    try {
      await service.moderateReport(report.id, status, notes: notes);
      if (mounted) {
        showSnack(context, 'Décision enregistrée');
        load();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildList(
      emptyIcon: Icons.flag_outlined,
      emptyTitle: 'Aucun signalement en attente',
      emptySubtitle: 'Les signalements des utilisateurs apparaîtront ici.',
      itemBuilder: (r) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.reportedName.isEmpty ? 'Utilisateur #${r.reportedUserId}' : r.reportedName,
                  style: AppTextStyles.labelMd),
              const SizedBox(height: 4),
              Text('Motif : ${r.reason}', style: AppTextStyles.bodyMd),
              if (r.details != null && r.details!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.details!, style: AppTextStyles.bodyMdMuted),
              ],
              const SizedBox(height: 8),
              Text(
                'Signalé par ${r.reporterName.isEmpty ? 'un utilisateur' : r.reporterName}'
                '${r.createdAt == null ? '' : ' · ${_formatDate(r.createdAt!)}'}',
                style: AppTextStyles.labelSm,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _decide(r), child: const Text('Décider')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ---------------------------------------------------------------- Vérifications

class _VerificationsTab extends StatefulWidget {
  const _VerificationsTab();

  @override
  State<_VerificationsTab> createState() => _VerificationsTabState();
}

class _VerificationsTabState extends _LoadableState<_VerificationsTab, ProfileResponse> {
  @override
  Future<List<ProfileResponse>> fetch() => service.getPendingVerifications();

  Future<void> _review(ProfileResponse profile, bool approved) async {
    final notes = await _askNotes(context, approved ? 'Approuver ce profil' : 'Refuser ce profil');
    if (notes == null) return;
    try {
      await service.reviewVerification(profile.userId, approved: approved, notes: notes);
      if (mounted) {
        showSnack(context, approved ? 'Profil vérifié ✅' : 'Vérification refusée');
        load();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildList(
      emptyIcon: Icons.verified_outlined,
      emptyTitle: 'Aucune vérification en attente',
      emptySubtitle: 'Les selfies envoyés par les utilisateurs apparaîtront ici.',
      itemBuilder: (p) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [if (p.displayName != null) p.displayName!, if (p.age != null) '${p.age} ans'].join(', '),
                style: AppTextStyles.labelMd,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PhotoBox(label: 'Photo du profil', child: _ProfilePhoto(url: p.photos.isEmpty ? null : p.photos.first.url))),
                  const SizedBox(width: 12),
                  Expanded(child: _PhotoBox(label: 'Selfie envoyé', child: _Selfie(userId: p.userId, service: service))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _review(p, false),
                    child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
                  ),
                  ElevatedButton(
                    onPressed: () => _review(p, true),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
                    child: const Text('Approuver'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _PhotoBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 3 / 4, child: child),
        ),
      ],
    );
  }
}

Widget _placeholder(IconData icon) => Container(
      color: AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.outline, size: 36),
    );

class _ProfilePhoto extends StatelessWidget {
  final String? url;
  const _ProfilePhoto({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) return _placeholder(Icons.person_off_outlined);
    return Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined));
  }
}

/// Télécharge le selfie avec le jeton (il n'a pas d'URL publique).
class _Selfie extends StatelessWidget {
  final int userId;
  final ModerationService service;
  const _Selfie({required this.userId, required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: service.getSelfie(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return _placeholder(Icons.broken_image_outlined);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
