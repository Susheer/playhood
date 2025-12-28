import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioController {
  AudioController._privateConstructor();

  static final AudioController _instance = AudioController._privateConstructor();

  factory AudioController() {
    return _instance;
  }

  final AudioPlayer player = AudioPlayer();
  SongModel? currentSong;
  bool loopSegment = false;
  Duration loopStart = Duration.zero;
  Duration loopEnd = Duration.zero;

  // Callbacks for UI updates
  Function()? onStateChanged;

  void setSong(SongModel song) async {
    currentSong = song;
    await player.setFilePath(song.data);
    player.play();
    _listenLoop();
    _notify();
  }

  void playPause() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
    _notify();
  }

  void seek(Duration position) {
    player.seek(position);
    _notify();
  }

  void setSpeed(double speed) {
    player.setSpeed(speed);
    _notify();
  }

  void setLoop(Duration start, Duration end) {
    loopStart = start;
    loopEnd = end;
    loopSegment = true;
  }

  void clearLoop() {
    loopSegment = false;
  }

  void _listenLoop() {
    player.positionStream.listen((pos) {
      if (loopSegment && pos >= loopEnd) {
        player.seek(loopStart);
      }
      _notify();
    });
  }

  void _notify() {
    if (onStateChanged != null) onStateChanged!();
  }
}
