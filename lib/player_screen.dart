import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'audio_manager.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;

  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _player = AudioManager.instance.player;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _player.duration ?? Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.song.title, style: const TextStyle(fontSize: 24)),
            Text(widget.song.artist ?? 'Unknown Artist'),
            const SizedBox(height: 40),
            Slider(
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              value: _position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
              onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(duration)),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 64,
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                  onPressed: () {
                    if (_isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text('Speed: ${_speed.toStringAsFixed(1)}x'),
                    Slider(
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      value: _speed,
                      onChanged: (value) {
                        setState(() {
                          _speed = value;
                          _player.setSpeed(_speed);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
