import 'package:audioplayers/audioplayers.dart';

/// Сервис для воспроизведения UI-звуков чата.
/// Синглтон — инициализируется один раз, держит плееры в памяти.
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  final AudioPlayer _sendPlayer = AudioPlayer();
  final AudioPlayer _receivePlayer = AudioPlayer();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _sendPlayer.setSource(AssetSource('sounds/outcome_message.wav'));
    await _receivePlayer.setSource(AssetSource('sounds/income_message.wav'));
    _initialized = true;
  }

  Future<void> playSend() async {
    await _sendPlayer.stop();
    await _sendPlayer.resume();
  }

  Future<void> playReceive() async {
    await _receivePlayer.stop();
    await _receivePlayer.resume();
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
