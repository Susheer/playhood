import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:playhood/audio_controller.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioController _controller = AudioController();
  double _speed = 1.0;
  Duration _loopStart = Duration.zero;
  Duration _loopEnd = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_controller.currentSong?.id != widget.song.id) {
      _controller.setSong(widget.song);
    }

    _controller.onStateChanged = () {
      setState(() {});
    };
  }

  String _format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller.player;
    final duration = player.duration ?? Duration.zero;
    final position = player.position;

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
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
              onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_format(position)), Text(_format(duration))],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 64,
                  icon: Icon(player.playing ? Icons.pause_circle : Icons.play_circle),
                  onPressed: () => _controller.playPause(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text('Playback Speed: ${_speed.toStringAsFixed(1)}x'),
                Slider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  value: _speed,
                  onChanged: (v) {
                    setState(() {
                      _speed = v;
                      _controller.setSpeed(_speed);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Loop Controls
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loop Segment'),
                Row(
                  children: [
                    Text('Start: ${_format(_loopStart)}'),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _loopStart = player.position,
                      child: const Text('Set Start'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('End: ${_format(_loopEnd)}'),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _loopEnd = player.position,
                      child: const Text('Set End'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _controller.setLoop(_loopStart, _loopEnd);
                      },
                      child: const Text('Enable Loop'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _controller.clearLoop();
                      },
                      child: const Text('Clear Loop'),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
