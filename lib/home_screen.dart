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
  final AudioPlayer _player = AudioPlayer(); // shared player
  List<SongModel> _songs = [];
  bool _loading = false;
  int? _playingIndex;

  // Looping
  bool _isLooping = false;
  Duration _loopStart = Duration.zero;
  Duration _loopEnd = Duration.zero;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    // Listen to position for mini-looping
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
    } catch (e) {
      print('Error loading songs: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _playSong(SongModel song, int index) async {
    if (_playingIndex == index && _player.playing) {
      await _player.pause();
    } else {
      await _player.setFilePath(song.data);
      _player.play();
      _playingIndex = index;
      _loopStart = Duration.zero;
      _loopEnd = _player.duration ?? Duration.zero;
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
        await _player.setFilePath(paths[0]);
        _player.play();
        _playingIndex = null; // external file
        _loopStart = Duration.zero;
        _loopEnd = _player.duration ?? Duration.zero;
        setState(() {});
      }
    }
  }

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    if (_isLooping) _player.seek(_loopStart);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
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
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  trailing: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () => _playSong(song, index),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          song: song,
                          player: _player,
                          loopStart: _loopStart,
                          loopEnd: _loopEnd,
                          isLooping: _isLooping,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // MINI PLAYER
          if (_player.playing || _playingIndex != null)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _playingIndex != null ? _songs[_playingIndex!].title : 'External File',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (_player.playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(_isLooping ? Icons.repeat_one : Icons.repeat),
                    onPressed: _toggleLoop,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
