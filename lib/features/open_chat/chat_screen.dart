import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/models/character.dart';
import '../../data/models/message.dart';
import '../../data/models/conversation.dart';
import '../../data/models/training_attempt_preview.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../services/practice_service.dart';
import '../../services/user_service.dart';
import '../../services/sound_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_chat_bubble.dart';
import '../../shared/widgets/dc_chat_input.dart';
import '../../shared/widgets/dc_credits_paywall.dart';
import '../../shared/widgets/dc_header.dart';
import '../practice/result_screen.dart';

/// Экран чата с персонажем
class ChatScreen extends StatefulWidget {
  final Character character;
  final String submodeId;
  final String? conversationId;
  final String title;
  final int? difficultyLevel;
  /// Если задан — в хедере появляется кнопка "Finish" / "Ready".
  /// Вызывается с текущим conversationId (null если разговор ещё не создан).
  final ValueChanged<String?>? onFinish;
  /// Если задан — чат открыт из истории тренировок.
  /// Кнопка в хедере: "Results" если есть feedback, "Finish" если нет.
  final TrainingConversationPreview? attemptPreview;

  const ChatScreen({
    super.key,
    required this.character,
    this.submodeId = 'open_chat',
    this.conversationId,
    this.title = 'Open Chat',
    this.difficultyLevel,
    this.onFinish,
    this.attemptPreview,
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
  bool _isSending = false;   // true только пока последнее сообщение ещё не прочитано (для read-статуса)
  bool _showTyping = false;
  bool _userSentMessage = false;
  MessageReadStatus _lastMessageReadStatus = MessageReadStatus.none;
  String? _error;

  /// Количество сообщений в очереди (отправлены но ответ ещё не получен)
  int _queueSize = 0;

  /// ID последнего отправленного local-сообщения (для read-статуса)
  String? _lastSentLocalId;

  /// Training message limit (null = unlimited, e.g. open_chat or coach modes)
  int? _messageLimit;
  /// Count of user messages sent in this conversation
  int _userMessageCount = 0;

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
    // Delete conversation only if it was newly created but user never replied.
    // Don't delete if we resumed an existing conversation (conversationId was passed in).
    if (_conversation != null && !_userSentMessage && widget.conversationId == null) {
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

    // Load message limit for training modes
    if (widget.difficultyLevel != null) {
      try {
        _messageLimit = await PracticeService().getMessageLimit(
          widget.submodeId,
          widget.difficultyLevel!,
        );
      } catch (_) {
        // Fallback: no limit enforcement if config unavailable
      }
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
          _userMessageCount = messages.where((m) => m.isUser).length;
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
            SoundService().playReceive();
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
    // Subscription check
    if (!UserService().canSendMessage) {
      final subscribed = await DCCreditsPaywall.show(context);
      if (!subscribed) return;
    }

    // 1. Добавляем пузырь мгновенно
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = Message(
      id: localId,
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _userSentMessage = true;
      _queueSize++;
      _isSending = true;
      _lastSentLocalId = localId;
      _lastMessageReadStatus = MessageReadStatus.sent;
    });
    SoundService().playSend();
    _scrollToBottom();

    // 2. Запускаем createConversation параллельно с анимацией
    Future<void>? createConvFuture;
    if (_conversation == null) {
      final characterId = widget.character.isCoach ? null : widget.character.id;
      createConvFuture = _repository.createConversation(
        submodeId: widget.submodeId,
        characterId: characterId,
        difficultyLevel: widget.difficultyLevel,
        language: 'en',
        seedMessage: _greetingContent,
      ).then((conv) {
        _conversation = conv;
      });
    }

    // 3. Sent → Read анимация (только для последнего сообщения)
    await Future.delayed(_randomDelay(640, 2000));
    if (!mounted) return;
    if (_lastSentLocalId == localId) {
      setState(() => _lastMessageReadStatus = MessageReadStatus.read);
    }

    // 4. Read → Typing
    await Future.delayed(_randomDelay(400, 1600));
    if (!mounted) return;

    // 5. Ждём conversation если нужно
    if (createConvFuture != null) {
      try {
        await createConvFuture;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.removeWhere((m) => m.id == localId);
          _queueSize = (_queueSize - 1).clamp(0, 999);
          if (_queueSize == 0) {
            _isSending = false;
            _showTyping = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start conversation')),
        );
        return;
      }
    }

    // 6. Показываем typing если ещё не показан
    if (!mounted) return;
    setState(() => _showTyping = true);
    _scrollToBottom();

    // 7. Отправляем запрос — бэкенд сам поставит в очередь
    final typingStartedAt = DateTime.now();
    try {
      final result = await _repository.sendMessage(
        conversationId: _conversation!.id,
        content: text,
      );

      if (!mounted) return;

      // Typing duration по длине ответа
      final responseLength = result.assistantMessage.content.length;
      final typingMs = (responseLength / 4.0 * 1000).round().clamp(1500, 8000);
      final elapsed = DateTime.now().difference(typingStartedAt).inMilliseconds;
      final remainingMs = typingMs - elapsed;
      if (remainingMs > 0) {
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      if (!mounted) return;

      setState(() {
        // Заменяем local-пузырь на реальный из ответа сервера
        final idx = _messages.indexWhere((m) => m.id == localId);
        if (idx != -1) _messages[idx] = result.userMessage;
        _messages.add(result.assistantMessage);

        _queueSize = (_queueSize - 1).clamp(0, 999);
        if (_queueSize == 0) {
          _isSending = false;
          _showTyping = false;
          _lastMessageReadStatus = MessageReadStatus.none;
        }
      });
      SoundService().playReceive();
      _scrollToBottom();

      _userMessageCount++;
      if (_messageLimit != null && _userMessageCount >= _messageLimit!) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && widget.onFinish != null) {
          widget.onFinish!(_conversation?.id);
          return;
        }
      }

      UserService().loadSubscriptionStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.id == localId);
        _queueSize = (_queueSize - 1).clamp(0, 999);
        if (_queueSize == 0) {
          _isSending = false;
          _showTyping = false;
          _lastMessageReadStatus = MessageReadStatus.none;
        }
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
              if (_messageLimit != null) _buildProgressBar(),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // История тренировок: кнопка Results (есть feedback) или Finish (нет feedback)
    if (widget.attemptPreview != null) {
      final attempt = widget.attemptPreview!;
      final hasResult = attempt.feedback != null;
      return DCHeader(
        title: widget.title,
        leading: const DCBackButton(),
        trailing: GestureDetector(
          onTap: () => _openAttemptResult(attempt),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              hasResult ? 'Results' : 'Finish',
              style: AppTypography.buttonAccent.copyWith(color: AppColors.action),
            ),
          ),
        ),
      );
    }

    // Кнопка Finish: для тренировок — только после первого сообщения юзера,
    // для pre_training (нет difficultyLevel) — сразу.
    final showFinish = widget.onFinish != null &&
        (widget.difficultyLevel == null || _userSentMessage);

    return DCHeader(
      title: widget.title,
      leading: const DCBackButton(),
      trailing: showFinish
          ? GestureDetector(
              onTap: () => widget.onFinish!(_conversation?.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  widget.difficultyLevel != null ? 'Finish' : 'Ready',
                  style: AppTypography.buttonAccent.copyWith(
                    color: AppColors.action,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _openAttemptResult(TrainingConversationPreview attempt) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        conversationId: attempt.conversationId,
        submodeId: attempt.submodeId,
        difficultyLevel: attempt.difficultyLevel ?? 1,
        trainingTitle: attempt.trainingTitle,
        onDone: () => Navigator.of(context).pop(),
        initialResult: attempt.feedback != null
            ? {
                'status': attempt.status,
                'feedback': {
                  'observed': attempt.feedback!.observed,
                  'interpretation': attempt.feedback!.interpretation,
                },
              }
            : null,
      ),
    ));
  }

  Widget _buildProgressBar() {
    final remaining = (_messageLimit! - _userMessageCount).clamp(0, _messageLimit!);
    final progress = _userMessageCount / _messageLimit!;
    final isLow = remaining <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: AppColors.inputBackground,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$remaining left',
            style: AppTypography.bodySmall.copyWith(
              color: isLow ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
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

    if (_messages.isEmpty && _queueSize == 0 && !_showTyping) {
      return _buildEmptyState();
    }

    return _buildMessagesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_messageLimit != null) ...[
              Text(
                'You have $_messageLimit messages to complete this level.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Say anything to start the conversation.\nThere\'s no wrong way to begin!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

        // System hint (centered gray text)
        if (message.isSystem) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final isFirstAssistantMessage = !message.isUser &&
            (reversedIndex == 0 || _messages.take(reversedIndex).where((m) => !m.isSystem).every((m) => m.isUser));

        // Read status: только для последнего отправленного сообщения
        MessageReadStatus readStatus = MessageReadStatus.none;
        if (message.isUser) {
          final isLastSent = message.id == _lastSentLocalId && _isSending;
          readStatus = isLastSent ? _lastMessageReadStatus : MessageReadStatus.read;
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
    final limitReached = _messageLimit != null && _userMessageCount >= _messageLimit!;
    return DCChatInput(
      onSend: _sendMessage,
      enabled: !limitReached,  // инпут всегда доступен пока не достигнут лимит
      hint: limitReached ? 'Message limit reached' : 'Type a message...',
    );
  }
}
