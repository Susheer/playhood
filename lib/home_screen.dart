import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:playhood/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _songs = [];
  bool _loading = false;
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermission();
    });

    // Listen for when audio finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingIndex = null;
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
      _songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
      );
      print('Loaded ${_songs.length} songs');
    } catch (e) {
      print('Error loading songs: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _playSong(SongModel song, int index) async {
    if (_playingIndex == index && _player.playing) {
      await _player.pause();
      setState(() => _playingIndex = null);
    } else {
      await _player.setFilePath(song.data);
      _player.play();
      setState(() => _playingIndex = index);
    }
  }

  Future<void> pickAudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<String> paths = result.paths.whereType<String>().toList();
      print('Selected files: $paths');
      // Optional: play first selected file
      if (paths.isNotEmpty) {
        playFile(paths[0]);
      }
    }
  }

  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    _player.play();
    setState(() => _playingIndex = null); // It's external file, not in _songs list
  }

  @override
  void dispose() {
    _player.dispose();
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
                final isPlaying = index == _playingIndex;

                return ListTile(
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(song: song),
                        ),
                      );
                      //_playSong(song, index);
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
