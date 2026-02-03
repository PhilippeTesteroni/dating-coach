import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_help_button.dart';
import '../../shared/widgets/dc_history_button.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../../shared/widgets/dc_modal.dart';
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
            'Open Chat is an unstructured conversation space.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semibold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You choose who you want to talk to based on how their way of responding feels to you.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'There is no right or wrong choice.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'You can always return to any conversation or delete it in the chat history.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }


  void _onCharacterTap(Character character) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(character: character),
      ),
    );
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
        onTap: () => showDCMenu(context, balance: UserService().balance),
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

  const _CharacterListItem({
    required this.character,
    this.onTap,
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
