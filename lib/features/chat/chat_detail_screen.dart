import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/message_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/message_service.dart';
import '../../core/services/safety_service.dart';
import '../../core/services/swipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

class ChatDetailScreen extends StatefulWidget {
  final int matchId;
  final int otherUserId;
  final String userName;
  final String? userPhotoUrl;

  const ChatDetailScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageService = MessageService();
  final _authService = AuthService();
  final _textController = TextEditingController();

  /// Du plus récent au plus ancien (liste inversée à l'écran).
  List<MessageResponse> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  int? _currentUserId;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _init();
    // Pas de WebSocket côté backend : on rafraîchit régulièrement.
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _init() async {
    _currentUserId = await _authService.getCurrentUserId();
    await _refresh(initial: true);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (_isSending) return;
    try {
      final fresh = await _messageService.getMessages(widget.matchId);
      if (!mounted) return;
      final changed = fresh.length != _messages.length ||
          (fresh.isNotEmpty && _messages.isNotEmpty && fresh.first.id != _messages.first.id);
      if (changed || initial) {
        setState(() {
          _messages = fresh;
          _error = null;
        });
      }
    } catch (e) {
      // Une erreur pendant le polling ne doit pas vider la conversation affichée
      if (mounted && (initial || _messages.isEmpty)) setState(() => _error = cleanError(e));
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final sent = await _messageService.sendMessage(widget.matchId, text);
      _textController.clear();
      if (mounted) setState(() => _messages = [sent, ..._messages]);
    } catch (e) {
      // Le texte reste dans le champ pour pouvoir réessayer
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onMenu(String action) async {
    try {
      switch (action) {
        case 'report':
          await _report();
          break;
        case 'block':
          if (await _confirm('Bloquer ${widget.userName} ?',
              'Vous ne verrez plus ce profil et il ne pourra plus vous contacter.', 'Bloquer')) {
            await SafetyService().block(widget.otherUserId);
            if (mounted) {
              showSnack(context, '${widget.userName} a été bloqué(e)');
              context.pop();
            }
          }
          break;
        case 'unmatch':
          if (await _confirm('Supprimer le match ?',
              'La conversation avec ${widget.userName} sera supprimée.', 'Supprimer')) {
            await SwipeService().unmatch(widget.matchId);
            if (mounted) context.pop();
          }
          break;
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  Future<void> _report() async {
    const reasons = {
      'SPAM': 'Spam ou arnaque',
      'HARASSMENT': 'Harcèlement',
      'FAKE_PROFILE': 'Faux profil',
      'INAPPROPRIATE': 'Contenu inapproprié',
      'OTHER': 'Autre',
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Signaler ${widget.userName}', style: AppTextStyles.headlineMd),
            ),
            for (final e in reasons.entries)
              ListTile(title: Text(e.value), onTap: () => Navigator.pop(ctx, e.key)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await SafetyService().report(widget.otherUserId, reason);
    if (mounted) showSnack(context, 'Signalement envoyé. Merci, notre équipe va l\'examiner.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(url: widget.userPhotoUrl, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.userName,
                  overflow: TextOverflow.ellipsis, style: AppTextStyles.labelMd.copyWith(fontSize: 16)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Signaler')),
              PopupMenuItem(value: 'block', child: Text('Bloquer')),
              PopupMenuItem(value: 'unmatch', child: Text('Supprimer le match')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null && _messages.isEmpty) {
      return ErrorView(
        message: _error!,
        onRetry: () {
          setState(() => _isLoading = true);
          _refresh(initial: true);
        },
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text('Envoyez un premier message à ${widget.userName} ! 🌶️', style: AppTextStyles.bodyMdMuted),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _currentUserId;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surfaceWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.content,
                    style: AppTextStyles.bodyMd.copyWith(color: isMe ? AppColors.white : AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  formatChatTime(msg.createdAt),
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 10,
                    color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLength: 2000,
                maxLines: null,
                textInputAction: TextInputAction.send,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
