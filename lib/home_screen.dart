import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'audio_controller.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    audioController.addListener(_onAudioChanged);
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission() async {
    await _audioQuery.permissionsRequest();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    _songs = await _audioQuery.querySongs();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    audioController.removeListener(_onAudioChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = audioController.currentSong;

    return Scaffold(
      appBar: AppBar(title: const Text('Playhood')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _loadSongs,
            child: const Text('Load Songs'),
          ),
          if (_loading) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isCurrent = currentSong?.id == song.id;
                final isPlaying = isCurrent && audioController.isPlaying;

                return ListTile(
                  title: Text(song.title, maxLines: 1),
                  subtitle: Text(song.artist ?? 'Unknown'),
                  trailing: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onTap: () {
                    audioController.playSong(song);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(song: song),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Mini Player
          if (currentSong != null)
            Container(
              color: Colors.deepPurple.shade100,
              child: ListTile(
                title: Text(currentSong.title, maxLines: 1),
                trailing: IconButton(
                  icon: Icon(audioController.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: audioController.togglePlayPause,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
