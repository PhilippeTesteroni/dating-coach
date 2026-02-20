import 'package:audioplayers/audioplayers.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Синглтон — инициализируется один раз, держит плееры в памяти.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  final AudioPlayer _sendPlayer = AudioPlayer();
  final AudioPlayer _receivePlayer = AudioPlayer();

  Future<void> init() async {
    // Устанавливаем громкость и режим
    await _sendPlayer.setVolume(1.0);
    await _receivePlayer.setVolume(1.0);
    // ReleaseMode.stop — после воспроизведения остаётся на позиции 0
    await _sendPlayer.setReleaseMode(ReleaseMode.stop);
    await _receivePlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playSend() async {
    await _sendPlayer.play(AssetSource('sounds/outcome_message.wav'));
  }

  Future<void> playReceive() async {
    await _receivePlayer.play(AssetSource('sounds/income_message.wav'));
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
