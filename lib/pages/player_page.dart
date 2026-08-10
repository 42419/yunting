import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/api_client.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.queue, required this.initialIndex});

  final List<Song> queue;
  final int initialIndex;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _player = AudioPlayer();
  late int _index = widget.initialIndex;
  String? _error;

  Song get _current => widget.queue[_index];

  @override
  void initState() {
    super.initState();
    _playCurrent();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _playCurrent() async {
    setState(() => _error = null);
    try {
      final uri = ApiClient.instance.streamUrl(_current);
      await _player.setUrl(uri.toString());
      await _player.play();
    } catch (e) {
      setState(() => _error = '播放失败: $e');
    }
  }

  void _playNext() {
    if (_index < widget.queue.length - 1) {
      setState(() => _index++);
      _playCurrent();
    }
  }

  void _playPrev() {
    if (_index > 0) {
      setState(() => _index--);
      _playCurrent();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('正在播放')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: _current.cover.isNotEmpty
                  ? Image.network(
                      _current.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.music_note, size: 72),
                    )
                  : const Icon(Icons.music_note, size: 72),
            ),
            const SizedBox(height: 24),
            Text(
              _current.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${_current.artist} · ${_current.source}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = _player.duration ?? Duration.zero;
                final max = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
                final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
                return Column(
                  children: [
                    Slider(
                      value: value,
                      max: max,
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(position)),
                          Text(_fmt(_player.duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  onPressed: _index > 0 ? _playPrev : null,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 16),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      iconSize: 56,
                      onPressed: () => playing ? _player.pause() : _player.play(),
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    );
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 36,
                  onPressed: _index < widget.queue.length - 1 ? _playNext : null,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
