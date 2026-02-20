import 'package:soundpool/soundpool.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Использует SoundPool — Android API специально для коротких UI-звуков.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  Soundpool? _pool;
  int _sendSoundId = -1;
  int _receiveSoundId = -1;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _pool = Soundpool.fromOptions(
        options: const SoundpoolOptions(maxStreams: 2),
      );
      _sendSoundId = await _pool!.loadUri('asset:///assets/sounds/outcome_message.wav');
      _receiveSoundId = await _pool!.loadUri('asset:///assets/sounds/income_message.wav');
      debugPrint('🔊 SoundService ready: send=$_sendSoundId receive=$_receiveSoundId');
    } catch (e) {
      debugPrint('🔊 SoundService init error: $e');
      _pool = null;
    }
  }

  Future<void> playSend() async {
    await _ensureInitialized();
    if (_pool == null || _sendSoundId < 0) return;
    debugPrint('🔊 playSend');
    await _pool!.play(_sendSoundId);
  }

  Future<void> playReceive() async {
    await _ensureInitialized();
    if (_pool == null || _receiveSoundId < 0) return;
    debugPrint('🔊 playReceive');
    await _pool!.play(_receiveSoundId);
  }
}
