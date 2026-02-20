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

  Future<void> init() async {
    debugPrint('🔊 SoundService init start');
    await _sendPlayer.setVolume(1.0);
    await _receivePlayer.setVolume(1.0);
    await _sendPlayer.setReleaseMode(ReleaseMode.stop);
    await _receivePlayer.setReleaseMode(ReleaseMode.stop);
    debugPrint('🔊 SoundService init done');
  }

  Future<void> playSend() async {
    debugPrint('🔊 playSend');
    await _sendPlayer.play(AssetSource('sounds/outcome_message.wav'));
  }

  Future<void> playReceive() async {
    debugPrint('🔊 playReceive');
    await _receivePlayer.play(AssetSource('sounds/income_message.wav'));
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
