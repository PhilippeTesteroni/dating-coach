import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Создаёт новый AudioPlayer на каждый вызов — надёжнее на Android.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  static const double _volume = 0.35;

  Future<void> init() async {
    debugPrint('🔊 SoundService init');
    // Прогрев: создаём и сразу отпускаем плеер чтобы Android инициализировал аудиосистему
    final warmup = AudioPlayer();
    await warmup.setVolume(0);
    await warmup.dispose();
  }

  Future<void> playSend() async {
    debugPrint('🔊 playSend');
    final player = AudioPlayer();
    await player.setVolume(_volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource('sounds/outcome_message.wav'));
  }

  Future<void> playReceive() async {
    debugPrint('🔊 playReceive');
    final player = AudioPlayer();
    await player.setVolume(_volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource('sounds/income_message.wav'));
  }
}
