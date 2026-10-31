import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/people_models.dart';
import '../../core/services/people_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

/// Retrouver quelqu'un qu'on connaît par son prénom ou son nom, et lui envoyer une demande.
/// Si elle accepte, la conversation apparaît dans les messages des deux personnes.
class PeopleSearchScreen extends StatefulWidget {
  /// Remplaçable dans les tests.
  final PeopleService? service;
  const PeopleSearchScreen({super.key, this.service});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  static const _minLetters = 3;

  late final PeopleService _service = widget.service ?? PeopleService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PersonSearchResult> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';
  final Set<int> _busy = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _hasQuery => _controller.text.trim().length >= _minLetters;

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      if (!_hasQuery) _results = [];
    });
    if (!_hasQuery) return;
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await _service.search(query);
      // Une réponse arrivée trop tard (l'utilisateur a continué à taper) est ignorée
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = results;
        _lastQuery = query;
      });
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replace(PersonSearchResult updated) {
    setState(() => _results = _results.map((r) => r.userId == updated.userId ? updated : r).toList());
  }

  Future<void> _request(PersonSearchResult person) async {
    if (_busy.contains(person.userId)) return;
    setState(() => _busy.add(person.userId));
    try {
      final result = await _service.sendRequest(person.userId);
      if (!mounted) return;
      if (result.matched) {
        _replace(person.copyWith(relation: PersonRelation.matched, matchId: result.matchId));
        showSnack(context, 'Vous êtes en contact avec ${person.displayName} : écrivez-lui !');
      } else {
        _replace(person.copyWith(relation: PersonRelation.requestSent));
        showSnack(context, 'Demande envoyée à ${person.displayName}. Si elle accepte, la conversation apparaîtra dans vos messages.');
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(person.userId));
    }
  }

  Future<void> _accept(PersonSearchResult person) async {
    if (_busy.contains(person.userId)) return;
    setState(() => _busy.add(person.userId));
    try {
      final result = await _service.accept(person.userId);
      if (!mounted) return;
      _replace(person.copyWith(relation: PersonRelation.matched, matchId: result.matchId));
      _openChat(person.copyWith(matchId: result.matchId));
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(person.userId));
    }
  }

  void _openChat(PersonSearchResult person) {
    final matchId = person.matchId;
    if (matchId == null) return;
    context.push('/chat/detail', extra: {
      'matchId': matchId,
      'otherUserId': person.userId,
      'userName': person.displayName,
      'userPhotoUrl': person.photoUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chercher quelqu\'un', style: AppTextStyles.headlineMd),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  if (_hasQuery) _search(v.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Prénom ou nom',
                  prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: AppColors.outline),
                          tooltip: 'Effacer',
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _search(_controller.text.trim()));
    }
    if (!_hasQuery) {
      return const EmptyView(
        icon: Icons.person_search_outlined,
        title: 'Retrouvez quelqu\'un que vous connaissez',
        subtitle: 'Tapez son prénom ou son nom. Elle recevra votre demande, et si elle accepte, '
            'la conversation s\'ouvre dans vos messages.',
      );
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'Personne trouvée pour « $_lastQuery »',
        subtitle: 'Vérifiez l\'orthographe. Les profils sans photo ni bio, ou que leur propriétaire a masqués, '
            'n\'apparaissent pas.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _PersonTile(
        person: _results[i],
        busy: _busy.contains(_results[i].userId),
        onRequest: () => _request(_results[i]),
        onAccept: () => _accept(_results[i]),
        onOpen: () => _openChat(_results[i]),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final PersonSearchResult person;
  final bool busy;
  final VoidCallback onRequest;
  final VoidCallback onAccept;
  final VoidCallback onOpen;

  const _PersonTile({
    required this.person,
    required this.busy,
    required this.onRequest,
    required this.onAccept,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final title = person.age == null ? person.displayName : '${person.displayName}, ${person.age}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          UserAvatar(url: person.photoUrl, radius: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.titleMd.copyWith(fontSize: 17))),
          const SizedBox(width: 8),
          _action(),
        ],
      ),
    );
  }

  Widget _action() {
    switch (person.relation) {
      case PersonRelation.none:
        return ElevatedButton(
          onPressed: busy ? null : onRequest,
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
          child: busy ? const _Spinner() : const Text('Demander'),
        );
      case PersonRelation.requestSent:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: AppColors.sidi),
            const SizedBox(width: 4),
            Text('Demande envoyée', style: AppTextStyles.labelMd.copyWith(color: AppColors.sidi)),
          ],
        );
      case PersonRelation.requestReceived:
        return ElevatedButton(
          onPressed: busy ? null : onAccept,
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
          child: busy ? const _Spinner() : const Text('Accepter'),
        );
      case PersonRelation.matched:
        return ElevatedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Discuter'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
            backgroundColor: AppColors.sidiTint,
            foregroundColor: AppColors.sidi,
            elevation: 0,
          ),
        );
    }
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
}
