import 'package:soundpool/soundpool.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Использует SoundPool — Android API специально для коротких UI-звуков.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  late final Soundpool _pool;
  int _sendSoundId = -1;
  int _receiveSoundId = -1;

  Future<void> init() async {
    debugPrint('🔊 SoundService init');
    _pool = Soundpool.fromOptions(
      options: const SoundpoolOptions(maxStreams: 2),
    );
    _sendSoundId = await _pool.loadUri(
      'asset:///assets/sounds/outcome_message.wav',
    );
    _receiveSoundId = await _pool.loadUri(
      'asset:///assets/sounds/income_message.wav',
    );
    debugPrint('🔊 SoundService init done: send=$_sendSoundId receive=$_receiveSoundId');
  }

  Future<void> playSend() async {
    debugPrint('🔊 playSend (id=$_sendSoundId)');
    if (_sendSoundId < 0) return;
    final streamId = await _pool.play(_sendSoundId);
    if (streamId > 0) await _pool.setVolume(soundId: _sendSoundId, streamId: streamId, volumeLeft: 0.35, volumeRight: 0.35);
  }

  Future<void> playReceive() async {
    debugPrint('🔊 playReceive (id=$_receiveSoundId)');
    if (_receiveSoundId < 0) return;
    final streamId = await _pool.play(_receiveSoundId);
    if (streamId > 0) await _pool.setVolume(soundId: _receiveSoundId, streamId: streamId, volumeLeft: 0.35, volumeRight: 0.35);
  }
}
