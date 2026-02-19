import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/models/character.dart';
import '../../data/models/message.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
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
  bool _isSending = false;    // блокирует input
  bool _showTyping = false;   // показывает typing bubble
  MessageReadStatus _lastMessageReadStatus = MessageReadStatus.none;
  String? _error;

  final _random = Random();

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

  /// Генерирует случайную задержку в диапазоне [minMs, maxMs]
  Duration _randomDelay(int minMs, int maxMs) =>
      Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs));

  Future<void> _sendMessage(String text) async {
    if (_conversation == null || _isSending) return;

    // Check subscription / free-tier limit before sending
    if (!UserService().canSendMessage) {
      final subscribed = await DCCreditsPaywall.show(context);
      if (!subscribed) return;
    }

    // 1. Show user message with "sent" status (empty circle)
    final userMessage = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _lastMessageReadStatus = MessageReadStatus.sent;
    });
    _scrollToBottom();

    // 2. Fire API request in background immediately
    final apiFuture = _repository.sendMessage(
      conversationId: _conversation!.id,
      content: text,
    );

    // 3. Sent → Read: random 800–2500ms
    await Future.delayed(_randomDelay(800, 2500));
    if (!mounted) return;
    setState(() {
      _lastMessageReadStatus = MessageReadStatus.read;
    });

    // 4. Read → Start typing: random 500–2000ms
    await Future.delayed(_randomDelay(500, 2000));
    if (!mounted) return;
    setState(() {
      _showTyping = true;
    });
    _scrollToBottom();

    // 5. Typing holds for min random 1500–4000ms, AND waits for API
    final typingMinFuture = Future.delayed(_randomDelay(1500, 4000));

    try {
      // Wait for both: API response + min typing time
      final result = await apiFuture;
      await typingMinFuture;

      if (!mounted) return;

      setState(() {
        _messages[_messages.length - 1] = result.userMessage;
        _messages.add(result.assistantMessage);
        _isSending = false;
        _showTyping = false;
        _lastMessageReadStatus = MessageReadStatus.none;
      });
      _scrollToBottom();

      UserService().loadSubscriptionStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.removeLast();
        _isSending = false;
        _showTyping = false;
        _lastMessageReadStatus = MessageReadStatus.none;
      });

      if (e is ApiException && e.isSubscriptionRequired) {
        await UserService().loadSubscriptionStatus();
        if (mounted) {
          await DCCreditsPaywall.show(context);
          if (mounted) setState(() {});
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
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

    if (_messages.isEmpty && !_isSending && !_showTyping) {
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
      itemCount: _messages.length + (_showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // reversed: index 0 = bottom (newest)
        final reversedIndex = _messages.length + (_showTyping ? 1 : 0) - 1 - index;

        // Typing indicator (last visual item = reversedIndex == count-1)
        if (_showTyping && reversedIndex == _messages.length) {
          return DCChatBubble.typing(
            avatarUrl: widget.character.thumbUrl,
            fullImageUrl: widget.character.avatarUrl,
            characterName: widget.character.name,
          );
        }

        final message = _messages[reversedIndex];
        final isFirstAssistantMessage = !message.isUser &&
            (reversedIndex == 0 || _messages.take(reversedIndex).every((m) => m.isUser));

        // Read status only for the last user message while sending
        final isLastUserMessage = message.isUser &&
            reversedIndex == _messages.length - 1 &&
            _isSending;

        return DCChatBubble(
          text: message.content,
          isUser: message.isUser,
          avatarUrl: message.isUser ? null : widget.character.thumbUrl,
          fullImageUrl: message.isUser ? null : widget.character.avatarUrl,
          characterName: widget.character.name,
          showName: isFirstAssistantMessage,
          readStatus: isLastUserMessage
              ? _lastMessageReadStatus
              : MessageReadStatus.none,
        );
      },
    );
  }

  Widget _buildFooter() {
    return DCChatInput(
      onSend: _sendMessage,
      enabled: !_isSending && _conversation != null,
    );
  }
}
