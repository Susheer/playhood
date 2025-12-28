import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer player;
  final Duration loopStart;
  final Duration loopEnd;
  final bool isLooping;

  const PlayerScreen({
    super.key,
    required this.song,
    required this.player,
    required this.loopStart,
    required this.loopEnd,
    required this.isLooping,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _player;
  late bool _isLooping;
  late Duration _loopStart;
  late Duration _loopEnd;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _isLooping = widget.isLooping;
    _loopStart = widget.loopStart;
    _loopEnd = widget.loopEnd;

    _duration = _player.duration ?? Duration.zero;

    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
      if (_isLooping && pos >= _loopEnd) {
        _player.seek(_loopStart);
      }
    });

    _player.playerStateStream.listen((state) {
      setState(() {
        _duration = _player.duration ?? Duration.zero;
      });
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(widget.song.artist ?? 'Unknown Artist'),
            const SizedBox(height: 20),
            Slider(
              min: 0,
              max: _duration.inMilliseconds.toDouble(),
              value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
              onChanged: (value) {
                _player.seek(Duration(milliseconds: value.toInt()));
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
                  icon: Icon(_player.playing ? Icons.pause_circle : Icons.play_circle),
                  onPressed: () {
                    if (_player.playing) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Loop Segment'),
            Row(
              children: [
                const Text('Start:'),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _loopStart.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                    onChanged: (value) {
                      setState(() => _loopStart = Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Text(_formatDuration(_loopStart)),
              ],
            ),
            Row(
              children: [
                const Text('End:'),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _loopEnd.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                    onChanged: (value) {
                      setState(() => _loopEnd = Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Text(_formatDuration(_loopEnd)),
              ],
            ),
            Row(
              children: [
                const Text('Speed:'),
                Expanded(
                  child: Slider(
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
                ),
                Text('${_speed.toStringAsFixed(1)}x'),
              ],
            ),
            Row(
              children: [
                const Text('Looping:'),
                Switch(
                  value: _isLooping,
                  onChanged: (val) {
                    setState(() => _isLooping = val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
