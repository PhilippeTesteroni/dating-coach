import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/models/character.dart';
import '../../data/models/message.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/user_service.dart';
import '../../services/sound_service.dart';
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
  final String title;

  const ChatScreen({
    super.key,
    required this.character,
    this.submodeId = 'open_chat',
    this.conversationId,
    this.title = 'Open Chat',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  late final ConversationsRepository _repository;
  
  Conversation? _conversation;
  String? _greetingContent;
  bool _isLoading = true;
  bool _isVisible = false;
  bool _isSending = false;
  bool _showTyping = false;
  bool _userSentMessage = false;
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
    // Delete conversation only if it was created but user never replied
    if (_conversation != null && !_userSentMessage) {
      _repository.deleteConversation(_conversation!.id).catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _initConversation() async {
    // Preload avatar into cache before showing chat
    final thumbUrl = widget.character.thumbUrl;
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      await CachedNetworkImageProvider(thumbUrl).resolve(const ImageConfiguration());
    }

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isVisible = true);
        });
      } else {
        // New conversation: fetch greeting only — no DB write yet
        final characterId = widget.character.isCoach ? null : widget.character.id;
        final greeting = await _repository.getGreeting(
          submodeId: widget.submodeId,
          characterId: characterId,
          language: 'en',
        );

        setState(() {
          _greetingContent = greeting.isNotEmpty ? greeting : null;
          if (_greetingContent != null) {
            _messages.add(Message(
              id: 'greeting_local',
              role: MessageRole.assistant,
              content: _greetingContent!,
              createdAt: DateTime.now(),
            ));
          }
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isVisible = true);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ _initConversation error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to start conversation';
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isVisible = true);
      });
    }
  }

  /// Генерирует случайную задержку в диапазоне [minMs, maxMs]
  Duration _randomDelay(int minMs, int maxMs) =>
      Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs));

  Future<void> _sendMessage(String text) async {
    if (_isSending) return;

    // Check subscription / free-tier limit before sending
    if (!UserService().canSendMessage) {
      final subscribed = await DCCreditsPaywall.show(context);
      if (!subscribed) return;
    }

    // 1. Показываем пузырь и играем звук мгновенно
    final userMessage = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _userSentMessage = true;
      _lastMessageReadStatus = MessageReadStatus.sent;
    });
    SoundService().playSend();
    _scrollToBottom();

    // 2. Создаём conversation если нужно (первое сообщение)
    if (_conversation == null) {
      try {
        final characterId = widget.character.isCoach ? null : widget.character.id;
        final conversation = await _repository.createConversation(
          submodeId: widget.submodeId,
          characterId: characterId,
          language: 'en',
          seedMessage: _greetingContent,
        );
        setState(() => _conversation = conversation);
      } catch (e) {
        setState(() {
          _messages.removeLast();
          _isSending = false;
          _lastMessageReadStatus = MessageReadStatus.none;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start conversation')),
        );
        return;
      }
    }

    // 3. Fire API request in background immediately
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
    final typingStartedAt = DateTime.now();
    setState(() {
      _showTyping = true;
    });
    _scrollToBottom();

    // 5. Wait for API, then hold typing based on response length
    try {
      final result = await apiFuture;

      if (!mounted) return;

      // Calculate typing duration: ~4 chars/sec, clamp 1.5s – 8s
      final responseLength = result.assistantMessage.content.length;
      final typingMs = (responseLength / 4.0 * 1000).round().clamp(1500, 8000);

      // Subtract time already spent showing "Writing..."
      final elapsed = DateTime.now().difference(typingStartedAt).inMilliseconds;
      final remainingMs = typingMs - elapsed;
      if (remainingMs > 0) {
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      if (!mounted) return;

      setState(() {
        _messages[_messages.length - 1] = result.userMessage;
        _messages.add(result.assistantMessage);
        _isSending = false;
        _showTyping = false;
        _lastMessageReadStatus = MessageReadStatus.none;
      });
      SoundService().playReceive();
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: widget.title,
      leading: const DCBackButton(),
    );
  }

  Widget _buildBody() {
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

        // Read status for user messages:
        // - Last user message while sending: animated sent → read
        // - All other user messages: always read (bot already "read" them)
        MessageReadStatus readStatus = MessageReadStatus.none;
        if (message.isUser) {
          final isLastUserMsg = reversedIndex == _messages.length - 1 && _isSending;
          readStatus = isLastUserMsg ? _lastMessageReadStatus : MessageReadStatus.read;
        }

        return DCChatBubble(
          text: message.content,
          isUser: message.isUser,
          avatarUrl: message.isUser ? null : widget.character.thumbUrl,
          fullImageUrl: message.isUser ? null : widget.character.avatarUrl,
          characterName: widget.character.name,
          showName: isFirstAssistantMessage,
          readStatus: readStatus,
        );
      },
    );
  }

  Widget _buildFooter() {
    return DCChatInput(
      onSend: _sendMessage,
      enabled: !_isSending,
    );
  }
}
