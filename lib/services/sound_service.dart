import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Синглтон — инициализируется один раз, держит плееры в памяти.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  final AudioPlayer _sendPlayer = AudioPlayer();
  final AudioPlayer _receivePlayer = AudioPlayer();

  static const double _volume = 0.35;

  Future<void> init() async {
    debugPrint('🔊 SoundService init start');
    await _sendPlayer.setVolume(_volume);
    await _receivePlayer.setVolume(_volume);
    await _sendPlayer.setReleaseMode(ReleaseMode.stop);
    await _receivePlayer.setReleaseMode(ReleaseMode.stop);
    // Прогреваем плееры чтобы не было задержки при первом вызове
    await _sendPlayer.setSource(AssetSource('sounds/outcome_message.wav'));
    await _receivePlayer.setSource(AssetSource('sounds/income_message.wav'));
    debugPrint('🔊 SoundService init done');
  }

  Future<void> playSend() async {
    debugPrint('🔊 playSend');
    await _sendPlayer.stop();
    await _sendPlayer.seek(Duration.zero);
    await _sendPlayer.resume();
  }

  Future<void> playReceive() async {
    debugPrint('🔊 playReceive');
    await _receivePlayer.stop();
    await _receivePlayer.seek(Duration.zero);
    await _receivePlayer.resume();
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
