import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'dc_photo_viewer.dart';

/// Статус прочтения сообщения (только для user messages)
enum MessageReadStatus {
  /// Нет индикатора (старые сообщения, assistant)
  none,
  /// Отправлено — пустой кружок
  sent,
  /// Прочитано — заполненный кружок (с анимацией)
  read,
}

/// Баббл сообщения в чате
class DCChatBubble extends StatelessWidget {
  final String? text;
  final bool isUser;
  final String? avatarUrl;
  final String? fullImageUrl;
  final String? characterName;
  final bool showName;
  final bool isTyping;
  final MessageReadStatus readStatus;

  const DCChatBubble({
    super.key,
    this.text,
    required this.isUser,
    this.avatarUrl,
    this.fullImageUrl,
    this.characterName,
    this.showName = false,
    this.isTyping = false,
    this.readStatus = MessageReadStatus.none,
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
        isTyping = true,
        readStatus = MessageReadStatus.none;

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
    if (isTyping) {
      // No bubble — just animated "Writing..." text aligned with avatar center
      return SizedBox(
        height: 32, // match avatar height
        child: const Align(
          alignment: Alignment.centerLeft,
          child: _AnimatedWritingText(),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? _userBubbleColor : _assistantBubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (readStatus == MessageReadStatus.none || !isUser) {
      return _buildText();
    }

    // User message with read status: check mark pinned bottom-right inside bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: _buildText()),
          const SizedBox(width: 4),
          _ReadStatusDot(status: readStatus),
        ],
      ),
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

  static const Color _userBubbleColor = Color(0xFFE8E0D8);
  static const Color _assistantBubbleColor = Color(0xFFD4C4B5);
}

// ─── Read status check mark ─────────────────────────────────

/// Галка статуса: серая при sent, персиково-оранжевая при read
class _ReadStatusDot extends StatelessWidget {
  final MessageReadStatus status;

  const _ReadStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRead = status == MessageReadStatus.read;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isRead ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, progress, _) {
        final color = Color.lerp(
          AppColors.textSecondary,
          AppColors.action,
          progress,
        )!;
        return Icon(
          Icons.check,
          size: 14,
          color: color,
        );
      },
    );
  }
}

// ─── Animated "Writing..." with cascading dots ──────────────

/// "Writing" + три точки, которые переливаются от первой к последней
class _AnimatedWritingText extends StatefulWidget {
  const _AnimatedWritingText();

  @override
  State<_AnimatedWritingText> createState() => _AnimatedWritingTextState();
}

class _AnimatedWritingTextState extends State<_AnimatedWritingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      fontStyle: FontStyle.italic,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Writing', style: baseStyle),
            _buildDot(0, baseStyle),
            _buildDot(1, baseStyle),
            _buildDot(2, baseStyle),
          ],
        );
      },
    );
  }

  /// Each dot lights up in sequence: 0→1→2 over the animation cycle
  Widget _buildDot(int index, TextStyle baseStyle) {
    // Each dot occupies 1/3 of the cycle, with overlap for smoothness
    final dotStart = index * 0.25;
    final dotEnd = dotStart + 0.4;

    double opacity;
    final t = _controller.value;
    if (t >= dotStart && t <= dotEnd) {
      // Fade in then out within the dot's window
      final local = (t - dotStart) / (dotEnd - dotStart);
      opacity = local <= 0.5
          ? (local * 2.0) // 0→1
          : (1.0 - (local - 0.5) * 2.0); // 1→0
      opacity = 0.3 + opacity * 0.7; // range: 0.3 – 1.0
    } else {
      opacity = 0.3;
    }

    return Opacity(
      opacity: opacity,
      child: Text('.', style: baseStyle),
    );
  }
}
