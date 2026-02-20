import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения UI-звуков чата.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  static const double _volume = 0.35;

  Future<void> init() async {
    debugPrint('🔊 SoundService init');
  }

  Future<void> _play(String asset) async {
    final player = AudioPlayer();
    await player.setVolume(_volume);
    await player.setReleaseMode(ReleaseMode.stop);
    // Ждём завершения воспроизведения, потом освобождаем
    player.onPlayerComplete.listen((_) => player.dispose());
    await player.play(AssetSource(asset));
  }

  Future<void> playSend() async {
    debugPrint('🔊 playSend');
    await _play('sounds/outcome_message.wav');
  }

  Future<void> playReceive() async {
    debugPrint('🔊 playReceive');
    await _play('sounds/income_message.wav');
  }
}
