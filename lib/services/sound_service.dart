import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
      final sendData = await rootBundle.load('assets/sounds/income_message.wav');
      final receiveData = await rootBundle.load('assets/sounds/outcome_message.wav');
      _sendSoundId = await _pool!.load(sendData);
      _receiveSoundId = await _pool!.load(receiveData);
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
    final streamId = await _pool!.play(_sendSoundId);
    if (streamId > 0) {
      await _pool!.setVolume(streamId: streamId, volume: 0.28);
    }
  }

  Future<void> playReceive() async {
    await _ensureInitialized();
    if (_pool == null || _receiveSoundId < 0) return;
    debugPrint('🔊 playReceive');
    final streamId = await _pool!.play(_receiveSoundId);
    if (streamId > 0) {
      await _pool!.setVolume(streamId: streamId, volume: 0.28);
    }
  }
}
