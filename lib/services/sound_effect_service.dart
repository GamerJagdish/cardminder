import 'package:audioplayers/audioplayers.dart';

/// Sound effect service using [audioplayers] configured for low-latency
/// media audio playback that routes to Bluetooth headphones, wired headsets,
/// or device speakers, respecting system media volume and mute.
class SoundEffectService {
  static final List<AudioPlayer> _players = [];
  static int _playerIndex = 0;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );

      for (int i = 0; i < 4; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _players.add(player);
      }
    } catch (_) {}
  }

  static Future<void> playHonk() async {
    if (!_initialized) {
      await init();
    }
    if (_players.isEmpty) return;

    try {
      final player = _players[_playerIndex % _players.length];
      _playerIndex++;
      await player.stop();
      await player.play(
        AssetSource('clown-horn-honks.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  static void dispose() {
    for (final p in _players) {
      p.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
