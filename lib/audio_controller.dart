import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();

  SongModel? currentSong;

  // Loop segment
  Duration? loopStart;
  Duration? loopEnd;
  bool loopEnabled = false;

  Timer? _loopTimer;

  bool get isPlaying => player.playing;

  AudioController() {
    player.positionStream.listen(_handleLoop);
  }

  Future<void> playSong(SongModel song) async {
    if (currentSong?.id != song.id) {
      currentSong = song;
      await player.setFilePath(song.data);
    }
    await player.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
    notifyListeners();
  }

  void setLoopStart(Duration d) {
    loopStart = d;
    notifyListeners();
  }

  void setLoopEnd(Duration d) {
    loopEnd = d;
    notifyListeners();
  }

  void toggleLoop() {
    loopEnabled = !loopEnabled;
    notifyListeners();
  }

  void clearLoop() {
    loopStart = null;
    loopEnd = null;
    loopEnabled = false;
    notifyListeners();
  }

  void _handleLoop(Duration position) {
    if (!loopEnabled || loopStart == null || loopEnd == null) return;
    if (position >= loopEnd!) {
      player.seek(loopStart);
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    player.dispose();
    super.dispose();
  }
}

final audioController = AudioController();
