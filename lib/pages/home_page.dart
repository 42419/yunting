import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/api_client.dart';
import 'player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<Song> _results = const [];
  bool _loading = false;
  String? _error;

  Future<void> _doSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final songs = await ApiClient.instance.search(keyword);
      setState(() => _results = songs);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openPlayer(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerPage(queue: _results, initialIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云听'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
              decoration: InputDecoration(
                hintText: '搜索歌曲，或直接粘贴歌曲/歌单链接',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _doSearch,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _loading ? '搜索中…' : '搜点什么听听吧',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final song = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          backgroundImage:
                              song.cover.isNotEmpty ? NetworkImage(song.cover) : null,
                          child: song.cover.isEmpty ? const Icon(Icons.music_note) : null,
                        ),
                        title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${song.artist} · ${song.source}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(song.durationText),
                        onTap: () => _openPlayer(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
