import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../data/models/conversation_preview.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_confirm_modal.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import 'chat_screen.dart';

/// Экран истории чатов для Open Chat
class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ConversationPreview> _conversations = [];
  Map<String, Character> _charactersMap = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Load characters + conversations in parallel
      final results = await Future.wait([
        CharactersService().getCharacters(preferredGender: 'all'),
        ConversationsRepository(UserService().apiClient)
            .getConversations('open_chat'),
      ]);

      final characters = results[0] as List<Character>;
      final conversations = results[1] as List<ConversationPreview>;

      // Build lookup map
      final map = <String, Character>{};
      for (final c in characters) {
        map[c.id] = c;
      }

      // Precache thumbs
      if (mounted) {
        final thumbs = conversations
            .where((c) => c.characterId != null && map.containsKey(c.characterId))
            .map((c) => map[c.characterId]!.thumbUrl)
            .toSet();
        await Future.wait(
          thumbs.map((url) => precacheImage(
            CachedNetworkImageProvider(url),
            context,
          )),
        );
      }

      setState(() {
        _conversations = conversations;
        _charactersMap = map;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onConversationTap(ConversationPreview preview) {
    final character = _charactersMap[preview.characterId];
    if (character == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: character,
          conversationId: preview.id,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(ConversationPreview preview) async {
    final confirmed = await DCConfirmModal.show(
      context,
      title: 'Delete chat?',
      message: 'This conversation will be permanently deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    if (confirmed != true) return false;

    try {
      await ConversationsRepository(UserService().apiClient)
          .deleteConversation(preview.id);
      setState(() {
        _conversations.removeWhere((c) => c.id == preview.id);
      });
      return false; // already removed manually
    } catch (e) {
      debugPrint('Delete failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DCHeader(
              title: 'Open Chat',
              leading: const DCBackButton(),
              trailing: DCMenuButton(
                onTap: () => showDCMenu(context, balance: UserService().balance),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load history',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final preview = _conversations[index];
        final character = _charactersMap[preview.characterId];
        return Dismissible(
          key: ValueKey(preview.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(preview),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
          ),
          child: _ChatHistoryCard(
            preview: preview,
            character: character,
            onTap: () => _onConversationTap(preview),
          ),
        );
      },
    );
  }
}

/// Карточка беседы в истории
class _ChatHistoryCard extends StatelessWidget {
  final ConversationPreview preview;
  final Character? character;
  final VoidCallback onTap;

  const _ChatHistoryCard({
    required this.preview,
    this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: character != null
          ? CachedNetworkImage(
              imageUrl: character!.thumbUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final letter = character?.name[0] ?? '?';
    return Center(
      child: Text(letter, style: AppTypography.titleMedium),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                character?.name ?? 'Unknown',
                style: AppTypography.titleMedium.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(preview.updatedAt),
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
        if (preview.lastMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            preview.lastMessage!,
            style: AppTypography.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final month = _months[date.month - 1];
    return '$month ${date.day}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
