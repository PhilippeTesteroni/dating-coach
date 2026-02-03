import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'dc_photo_viewer.dart';

/// Баббл сообщения в чате
/// 
/// [text] — текст сообщения
/// [isUser] — true для сообщений пользователя (справа)
/// [avatarUrl] — URL аватара для assistant (слева)
/// [characterName] — имя персонажа (показывается над первым сообщением)
/// [showName] — показывать ли имя над сообщением
/// [isTyping] — показать "Typing..." вместо текста
class DCChatBubble extends StatelessWidget {
  final String? text;
  final bool isUser;
  final String? avatarUrl;
  final String? fullImageUrl;
  final String? characterName;
  final bool showName;
  final bool isTyping;

  const DCChatBubble({
    super.key,
    this.text,
    required this.isUser,
    this.avatarUrl,
    this.fullImageUrl,
    this.characterName,
    this.showName = false,
    this.isTyping = false,
  });

  /// Typing indicator bubble
  const DCChatBubble.typing({
    super.key,
    this.avatarUrl,
    this.fullImageUrl,
    this.characterName,
  })  : text = null,
        isUser = false,
        showName = false,
        isTyping = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName && characterName != null && !isUser)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Text(
                characterName!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: isUser ? _buildUserRow() : _buildAssistantRow(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserRow() {
    return [
      _buildBubble(),
      const SizedBox(width: 8),
      _buildUserAvatar(),
    ];
  }

  List<Widget> _buildAssistantRow() {
    return [
      _buildCharacterAvatar(),
      const SizedBox(width: 8),
      _buildBubble(),
    ];
  }

  Widget _buildBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? _userBubbleColor : _assistantBubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isTyping ? _buildTypingIndicator() : _buildText(),
    );
  }

  Widget _buildText() {
    return Text(
      text ?? '',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Text(
      'Typing...',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 18,
        color: AppColors.background,
      ),
    );
  }

  Widget _buildCharacterAvatar() {
    final avatar = _buildCharacterAvatarImage();
    
    if (fullImageUrl == null || fullImageUrl!.isEmpty) {
      return avatar;
    }

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => DCPhotoViewer.show(
          context,
          imageUrl: fullImageUrl!,
        ),
        child: avatar,
      ),
    );
  }

  Widget _buildCharacterAvatarImage() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            characterName?.isNotEmpty == true ? characterName![0] : '?',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 32,
          height: 32,
          color: AppColors.inputBackground,
        ),
        errorWidget: (_, __, ___) => Container(
          width: 32,
          height: 32,
          color: AppColors.textPrimary,
          child: Center(
            child: Text(
              characterName?.isNotEmpty == true ? characterName![0] : '?',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Цвет баббла пользователя (светлый бежевый)
  static const Color _userBubbleColor = Color(0xFFE8E0D8);

  // Цвет баббла ассистента (тёплый песочный)
  static const Color _assistantBubbleColor = Color(0xFFD4C4B5);
}
