import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:playhood/audio_controller.dart';
import 'package:playhood/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioController _controller = AudioController();
  List<SongModel> _songs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    _controller.onStateChanged = () {
      setState(() {});
    };
  }

  Future<void> _requestPermission() async {
    bool granted = await _audioQuery.permissionsRequest();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    try {
      _songs = await _audioQuery.querySongs(sortType: SongSortType.TITLE);
    } catch (e) {
      print('Error loading songs: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> pickAudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<String> paths = result.paths.whereType<String>().toList();
      if (paths.isNotEmpty) {
        // Play first selected file
        _controller.player.setFilePath(paths[0]);
        _controller.player.play();
        setState(() {});
      }
    }
  }

  Widget miniPlayer() {
    if (_controller.currentSong == null) return const SizedBox.shrink();
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _controller.currentSong!.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(_controller.player.playing ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              _controller.playPause();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(song: _controller.currentSong!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playhood')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _loadSongs,
                child: const Text('Load Audio Files'),
              ),
              ElevatedButton(
                onPressed: pickAudioFiles,
                child: const Text('Pick Audio File'),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isPlaying = _controller.currentSong?.id == song.id;

                return ListTile(
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      _controller.setSong(song);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayerScreen(song: song)),
                    );
                  },
                );
              },
            ),
          ),
          miniPlayer(),
        ],
      ),
    );
  }
}
