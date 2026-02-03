import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../data/models/message.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/app_settings_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_credits_badge.dart';
import '../../shared/widgets/dc_chat_bubble.dart';
import '../../shared/widgets/dc_chat_input.dart';
import '../../shared/widgets/dc_credits_paywall.dart';
import '../../shared/widgets/dc_header.dart';

/// Экран чата с персонажем
class ChatScreen extends StatefulWidget {
  final Character character;
  final String submodeId;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.character,
    this.submodeId = 'open_chat',
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  late final ConversationsRepository _repository;
  
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ConversationsRepository(UserService().apiClient);
    _initConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initConversation() async {
    try {
      if (widget.conversationId != null) {
        // Resume existing conversation — load messages
        final messages = await _repository.getMessages(widget.conversationId!);
        setState(() {
          _conversation = Conversation(
            id: widget.conversationId!,
            modeId: '',
            submodeId: widget.submodeId,
            actorType: ActorType.character,
            language: 'en',
            isActive: true,
            createdAt: DateTime.now(),
          );
          _messages.addAll(messages);
          _isLoading = false;
        });
      } else {
        // New conversation
        final conversation = await _repository.createConversation(
          submodeId: widget.submodeId,
          characterId: widget.character.id,
          language: 'en',
        );
        
        setState(() {
          _conversation = conversation;
          _isLoading = false;
          if (conversation.firstMessage != null) {
            _messages.add(conversation.firstMessage!);
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start conversation';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (_conversation == null || _isSending) return;

    // Check credits before sending
    final cost = AppSettingsService().creditCost;
    if (UserService().balance < cost) {
      DCCreditsPaywall.show(context);
      return;
    }

    // Show user message immediately
    final userMessage = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await _repository.sendMessage(
        conversationId: _conversation!.id,
        content: text,
      );

      setState(() {
        // Replace local message with server one
        _messages[_messages.length - 1] = result.userMessage;
        _messages.add(result.assistantMessage);
        _isSending = false;
      });

      // Update balance from server response
      if (result.newBalance != null) {
        UserService().updateBalance(result.newBalance!);
      }
    } catch (e) {
      setState(() => _isSending = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: 'Open Chat',
      leading: const DCBackButton(),
      trailing: DCCreditsBadge(credits: UserService().balance),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initConversation();
              },
              child: Text('Tap to retry', style: AppTypography.buttonAccent),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty && !_isSending) {
      return _buildEmptyState();
    }

    return _buildMessagesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Text(
          'Just say anything to start the conversation.\nThere\'s no wrong way to begin!',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        // reversed: index 0 = bottom (newest)
        final reversedIndex = _messages.length + (_isSending ? 1 : 0) - 1 - index;

        // Typing indicator (last visual item = reversedIndex == count-1)
        if (_isSending && reversedIndex == _messages.length) {
          return DCChatBubble.typing(
            avatarUrl: widget.character.thumbUrl,
            fullImageUrl: widget.character.avatarUrl,
            characterName: widget.character.name,
          );
        }

        final message = _messages[reversedIndex];
        final isFirstAssistantMessage = !message.isUser &&
            (reversedIndex == 0 || _messages.take(reversedIndex).every((m) => m.isUser));

        return DCChatBubble(
          text: message.content,
          isUser: message.isUser,
          avatarUrl: message.isUser ? null : widget.character.thumbUrl,
          fullImageUrl: message.isUser ? null : widget.character.avatarUrl,
          characterName: widget.character.name,
          showName: isFirstAssistantMessage,
        );
      },
    );
  }

  Widget _buildFooter() {
    final creditCost = AppSettingsService().creditCost;
    final costText = creditCost == 1 
        ? '1 credit per message' 
        : '$creditCost credits per message';
    
    return Column(
      children: [
        DCChatInput(
          onSend: _sendMessage,
          enabled: !_isSending && _conversation != null,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            costText,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
