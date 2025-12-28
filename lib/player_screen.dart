import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'audio_controller.dart';

class PlayerScreen extends StatefulWidget {
  final SongModel song;

  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    audioController.player.positionStream.listen((p) {
      setState(() => position = p);
    });
    audioController.player.durationStream.listen((d) {
      setState(() => duration = d ?? Duration.zero);
    });
  }

  String fmt(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final c = audioController;

    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.song.title, style: const TextStyle(fontSize: 22)),
            Slider(
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
              onChanged: (v) {
                c.player.seek(Duration(milliseconds: v.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(fmt(position)), Text(fmt(duration))],
            ),
            IconButton(
              iconSize: 64,
              icon: Icon(c.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: c.togglePlayPause,
            ),

            const Divider(),

            // Loop controls
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => c.setLoopStart(position),
                  child: const Text('Set Loop Start'),
                ),
                ElevatedButton(
                  onPressed: () => c.setLoopEnd(position),
                  child: const Text('Set Loop End'),
                ),
                ElevatedButton(
                  onPressed: c.toggleLoop,
                  child: Text(c.loopEnabled ? 'Disable Loop' : 'Enable Loop'),
                ),
                TextButton(
                  onPressed: c.clearLoop,
                  child: const Text('Clear Loop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
