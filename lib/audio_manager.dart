import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._privateConstructor();

  static final AudioManager _instance = AudioManager._privateConstructor();

  static AudioManager get instance => _instance;

  final AudioPlayer player = AudioPlayer();

  int? currentIndex;
}
