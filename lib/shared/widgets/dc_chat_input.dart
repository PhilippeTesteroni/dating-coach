import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Поле ввода сообщения в чате
/// 
/// TextField с placeholder + круглая кнопка отправки
class DCChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool enabled;
  final String hint;

  const DCChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hint = 'Type a message...',
  });

  @override
  State<DCChatInput> createState() => _DCChatInputState();
}

class _DCChatInputState extends State<DCChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onTapOutside: (_) {},
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && widget.enabled;
    
    return GestureDetector(
      onTap: canSend ? _send : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: canSend ? AppColors.textPrimary : AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward,
          color: AppColors.background,
          size: 24,
        ),
      ),
    );
  }
}
