import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:playhood/player_screen.dart';
import 'audio_manager.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermission();
    });

    // Listen for when audio finishes
    AudioManager.instance.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          AudioManager.instance.currentIndex = null;
        });
      }
    });
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
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _requestPermission();
    }

    setState(() => _loading = true);

    try {
      _songs = await _audioQuery.querySongs(sortType: SongSortType.TITLE);
      print('Loaded ${_songs.length} songs');
    } catch (e) {
      print('Error loading songs: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _playSong(SongModel song, int index) async {
    final player = AudioManager.instance.player;

    if (AudioManager.instance.currentIndex == index && player.playing) {
      await player.pause();
      AudioManager.instance.currentIndex = null;
    } else {
      await player.setFilePath(song.data);
      player.play();
      AudioManager.instance.currentIndex = index;
    }

    setState(() {});
  }

  Future<void> pickAudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<String> paths = result.paths.whereType<String>().toList();
      if (paths.isNotEmpty) {
        final player = AudioManager.instance.player;
        await player.setFilePath(paths[0]);
        player.play();
        AudioManager.instance.currentIndex = null;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    AudioManager.instance.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = AudioManager.instance.currentIndex;

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
                final isPlaying = index == currentIndex;

                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  trailing: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      _playSong(song, index);
                      // Navigate to player screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(song: song),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
