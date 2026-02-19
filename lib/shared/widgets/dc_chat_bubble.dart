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
///
/// [text] — текст сообщения
/// [isUser] — true для сообщений пользователя (справа)
/// [avatarUrl] — URL аватара для assistant (слева)
/// [characterName] — имя персонажа (показывается над первым сообщением)
/// [showName] — показывать ли имя над сообщением
/// [isTyping] — показать "Writing..." вместо текста
/// [readStatus] — статус прочтения (sent/read) для user messages
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
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBubble(),
          if (readStatus != MessageReadStatus.none)
            _buildReadIndicator(),
        ],
      ),
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
      'Writing...',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Кружок read status под баблом пользователя
  Widget _buildReadIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: _ReadStatusDot(status: readStatus),
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

/// Анимированный кружок read status
///
/// sent → пустой контур (как на скрине 2)
/// read → заполненный (как на скрине 1), с плавной анимацией заливки
class _ReadStatusDot extends StatelessWidget {
  final MessageReadStatus status;

  const _ReadStatusDot({required this.status});

  static const double _size = 10.0;
  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final isRead = status == MessageReadStatus.read;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isRead ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, fillProgress, _) {
        return CustomPaint(
          size: const Size(_size, _size),
          painter: _ReadDotPainter(
            fillProgress: fillProgress,
            color: AppColors.textPrimary,
            borderWidth: _borderWidth,
          ),
        );
      },
    );
  }
}

/// Рисует кружок: контур всегда, заливка по fillProgress (0.0 → 1.0)
class _ReadDotPainter extends CustomPainter {
  final double fillProgress;
  final Color color;
  final double borderWidth;

  _ReadDotPainter({
    required this.fillProgress,
    required this.color,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - borderWidth;

    // Контур — всегда
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, outerRadius - borderWidth / 2, borderPaint);

    // Заливка — по прогрессу
    if (fillProgress > 0.0) {
      final fillPaint = Paint()
        ..color = color.withOpacity(fillProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius * fillProgress, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_ReadDotPainter oldDelegate) =>
      fillProgress != oldDelegate.fillProgress;
}
