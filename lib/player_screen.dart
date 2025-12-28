import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer player; // Shared player from HomeScreen

  const PlayerScreen({super.key, required this.song, required this.player});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _speed = 1.0;

  // Segment loop range
  Duration? _loopStart;
  Duration? _loopEnd;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setFilePath(widget.song.data);
      _duration = _player.duration ?? Duration.zero;

      _player.positionStream.listen((pos) {
        setState(() {
          _position = pos;

          // Segment loop logic
          if (_loopStart != null && _loopEnd != null && pos >= _loopEnd!) {
            _player.seek(_loopStart);
          }
        });
      });

      _player.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _player.seek(Duration.zero);
            _player.pause();
          }
        });
      });

      _player.play();
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    // Do not dispose shared player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.song.artist ?? 'Unknown Artist'),
            const SizedBox(height: 20),
            // Segment loop sliders
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Loop Start'),
                      Slider(
                        min: 0,
                        max: _duration.inMilliseconds.toDouble(),
                        value: (_loopStart?.inMilliseconds ?? 0).clamp(0, _duration.inMilliseconds).toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _loopStart = Duration(milliseconds: value.toInt());
                          });
                        },
                      ),
                      Text(_loopStart != null ? _formatDuration(_loopStart!) : '0:00'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Loop End'),
                      Slider(
                        min: 0,
                        max: _duration.inMilliseconds.toDouble(),
                        value: (_loopEnd?.inMilliseconds ?? _duration.inMilliseconds).clamp(0, _duration.inMilliseconds).toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _loopEnd = Duration(milliseconds: value.toInt());
                          });
                        },
                      ),
                      Text(_loopEnd != null ? _formatDuration(_loopEnd!) : _formatDuration(_duration)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Slider(
              min: 0,
              max: _duration.inMilliseconds.toDouble(),
              value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
              onChanged: (value) {
                final pos = Duration(milliseconds: value.toInt());
                _player.seek(pos);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
            const SizedBox(height: 20),
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
                const SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
