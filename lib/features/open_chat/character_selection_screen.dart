import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../data/models/conversation_preview.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_help_button.dart';
import '../../shared/widgets/dc_history_button.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../../shared/widgets/dc_modal.dart';
import '../../shared/widgets/dc_confirm_modal.dart';
import '../../shared/widgets/dc_header.dart';
import 'chat_screen.dart';
import 'chat_history_screen.dart';

/// Экран выбора персонажа для Open Chat
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  List<Character> _characters = [];
  bool _isLoading = true;
  String? _error;
  String? _loadingCharacterId;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    try {
      final profile = UserService().profile;
      final preferredGender = profile?.preferredGender.name ?? 'all';
      
      debugPrint('Loading characters with preferredGender: $preferredGender');
      
      // Используем CharactersService с кэшированием
      final characters = await CharactersService().getCharacters(
        preferredGender: preferredGender,
      );
      
      debugPrint('Loaded ${characters.length} characters');

      // Precache all thumb images before showing the list
      if (mounted) {
        await Future.wait(
          characters.map((c) => precacheImage(
            CachedNetworkImageProvider(c.thumbUrl),
            context,
          )),
        );
      }
      
      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading characters: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showHelpModal() {
    DCModal.show(
      context: context,
      title: 'Open Chat',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open Chat is a free-form space with no structure, no levels, and no feedback.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'You choose a character and just talk. Each character has a distinct personality and responds based on how the conversation actually goes — they can lose interest, warm up, push back, or engage, depending on what you bring.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'There\'s no goal and no wrong move. Good for warming up, experimenting, or just having a conversation that feels real.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'You can return to any previous conversation or start a new one at any time.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }


  Future<void> _onCharacterTap(Character character) async {
    if (_loadingCharacterId != null) return; // prevent double tap
    setState(() => _loadingCharacterId = character.id);

    // Load existing conversations for this character
    try {
      final allConversations = await ConversationsRepository(UserService().apiClient)
          .getConversations('open_chat');

      final characterConversations = allConversations
          .where((c) => c.characterId == character.id)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;

      if (characterConversations.isNotEmpty) {
        final latest = characterConversations.first;
        final lastMsg = latest.lastMessage?.trim();
        // Build preview: show message count + last message if available
        String message;
        if (lastMsg != null && lastMsg.isNotEmpty) {
          // Use Characters to safely truncate without breaking emoji/surrogate pairs
          final chars = lastMsg.characters;
          final truncated = chars.length > 80 ? '${chars.take(80)}…' : lastMsg;
          message = 'You have a conversation with ${character.name}.\n\nLast message: "$truncated"';
        } else {
          message = 'You have a conversation with ${character.name}.';
        }

        setState(() => _loadingCharacterId = null);

        final result = await DCConfirmModal.show(
          context: context,
          title: 'Continue conversation?',
          message: message,
          confirmText: 'Continue',
          cancelText: 'Start new',
        );

        if (!mounted) return;

        if (result == true) {
          // Continue existing
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                character: character,
                conversationId: latest.id,
              ),
            ),
          );
        } else if (result == false) {
          // Start new
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(character: character),
            ),
          );
        }
        // result == null (dismissed) — do nothing
      } else {
        setState(() => _loadingCharacterId = null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(character: character),
          ),
        );
      }
    } catch (e) {
      // On error — fallback to new conversation
      if (!mounted) return;
      setState(() => _loadingCharacterId = null);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(character: character),
        ),
      );
    }
  }

  void _onHistoryTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChatHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 48),
                    Expanded(child: _buildContent()),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return DCHeader(
      title: 'Open Chat',
      leading: DCHelpButton(onTap: _showHelpModal),
      trailing: DCMenuButton(
        onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
      ),
    );
  }

  Widget _buildTitle() {
    return Text.rich(
      TextSpan(
        style: AppTypography.titleLarge,
        children: [
          const TextSpan(text: 'Who would you like to '),
          TextSpan(
            text: 'talk',
            style: AppTypography.titleLargeAccent,
          ),
          const TextSpan(text: ' with right now?'),
        ],
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
          'Failed to load characters',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: _characters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _CharacterListItem(
          character: _characters[index],
          isLoading: _loadingCharacterId == _characters[index].id,
          onTap: () => _onCharacterTap(_characters[index]),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Center(
      child: DCHistoryButton(onTap: _onHistoryTap),
    );
  }
}


/// Элемент списка персонажей
class _CharacterListItem extends StatelessWidget {
  final Character character;
  final VoidCallback? onTap;
  final bool isLoading;

  const _CharacterListItem({
    required this.character,
    this.onTap,
    this.isLoading = false,
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
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.inputBackground,
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: character.thumbUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Text(
                character.name[0],
                style: AppTypography.titleMedium,
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background.withOpacity(0.6),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.action,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          character.name,
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          character.description,
          style: AppTypography.bodySmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
